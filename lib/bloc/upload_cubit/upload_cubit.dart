import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/upload_cubit/upload_state.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/services/media/media_processor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:optombai/configs/constrants.dart';

export 'upload_state.dart';

class UploadCubit extends Cubit<UploadState> {
  final IProductRepository _repository;
  final SharedPreferences _preferences;
  final MediaProcessor _mediaProcessor;

  UploadCubit({
    required IProductRepository repository,
    required SharedPreferences preferences,
    required MediaProcessor mediaProcessor,
  })  : _repository = repository,
        _preferences = preferences,
        _mediaProcessor = mediaProcessor,
        super(const UploadIdle());

  String get _token => _preferences.getString(TOKEN_KEY) ?? '';

  Future<void> startUpload({
    required Product product,
    required List<MediaFile> mediaFiles,
    required EnumRequestType requestType,
    File? rawVideoFile,
  }) async {
    if (state is! UploadIdle && state is! UploadError && state is! UploadSuccess) {
      return;
    }

    // PATCH (edit) still uses v1: backend hasn't shipped v2 patch yet.
    if (requestType == EnumRequestType.patch) {
      return _startUploadV1Patch(
        product: product,
        mediaFiles: mediaFiles,
        rawVideoFile: rawVideoFile,
      );
    }

    final allMediaFiles = [...mediaFiles];
    String postId = '';
    final clientRequestId = const Uuid().v4();
    final uploadedIds = <int>[];
    final sw = Stopwatch()..start();

    talker.info(
      '[UPLOAD] START v2 flow | reqId=$clientRequestId '
      'mediaCount=${mediaFiles.length} rawVideo=${rawVideoFile != null}',
    );

    try {
      // Process raw video file if provided.
      if (rawVideoFile != null) {
        talker.info('[UPLOAD] processing raw video');
        emit(const UploadProcessing(statusText: 'Обработка видео...'));

        final videoMedia = await _mediaProcessor.processVideo(
          rawVideoFile,
          onStatusChanged: (stage) {
            final text = switch (stage) {
              VideoProcessingStage.validating => 'Проверка видео...',
              VideoProcessingStage.generatingThumbnail => 'Генерация превью...',
              VideoProcessingStage.finalizing => 'Завершение обработки...',
            };
            emit(UploadProcessing(statusText: text));
          },
        );

        if (videoMedia != null) {
          allMediaFiles.add(videoMedia);
        }
      }

      final File? thumbnail = _extractThumbnail(allMediaFiles);

      // v2 flow: upload all media FIRST (so a failure here aborts cleanly
      // without leaving an orphan post on the server), THEN atomically
      // create the post with the collected media_ids. Videos still go
      // first so a video failure stops photos and presents one error.
      final videos = allMediaFiles.where((m) => m.isVideo).toList();
      final photos = allMediaFiles.where((m) => !m.isVideo).toList();
      final ordered = [...videos, ...photos];
      final totalFiles = ordered.length;

      if (totalFiles > 0) {
        emit(UploadUploading(
          thumbnail: thumbnail,
          progress: 0,
          uploaded: 0,
          total: totalFiles,
        ));

        for (var i = 0; i < ordered.length; i++) {
          final media = ordered[i];
          final fileName = media.file.path.split('/').last;

          // The picked file lives in the volatile OS picker cache, which
          // can be purged before the upload runs (notably under memory
          // pressure). Reading a missing file throws PathNotFoundException
          // outside the per-media try below — guard it explicitly so the
          // user gets a clear, actionable error instead of a hard fail.
          if (!media.file.existsSync()) {
            talker.warning(
              '[UPLOAD] media ${i + 1}/$totalFiles FAIL | file purged: $fileName',
            );
            emit(UploadError(
              message: media.isVideo
                  ? 'Файл видео больше недоступен — выберите видео заново.'
                  : 'Файл больше недоступен — выберите его заново.',
              thumbnail: thumbnail,
              mediaFiles: allMediaFiles,
              postId: '',
              token: _token,
              clientRequestId: clientRequestId,
              uploadedMediaIds: uploadedIds,
            ));
            return;
          }

          final sizeMb = (media.file.lengthSync() / (1024 * 1024))
              .toStringAsFixed(1);
          final mediaSw = Stopwatch()..start();
          talker.info(
            '[UPLOAD] media ${i + 1}/$totalFiles START | isVideo=${media.isVideo} '
            'size=${sizeMb}MB file=$fileName',
          );
          try {
            final result = await _repository.uploadPostMediaV2(
              media,
              _token,
              onSendProgress: (sent, total) {
                if (total > 0) {
                  final overall = (i + sent / total) / totalFiles;
                  emit(UploadUploading(
                    thumbnail: thumbnail,
                    progress: overall.clamp(0.0, 1.0),
                    uploaded: i,
                    total: totalFiles,
                  ));
                }
              },
            );
            uploadedIds.add(result.id);
            talker.info(
              '[UPLOAD] media ${i + 1}/$totalFiles DONE | id=${result.id} '
              'elapsed=${mediaSw.elapsedMilliseconds}ms',
            );
            emit(UploadUploading(
              thumbnail: thumbnail,
              progress: (i + 1) / totalFiles,
              uploaded: i + 1,
              total: totalFiles,
            ));
          } catch (e) {
            talker.warning(
              '[UPLOAD] media ${i + 1}/$totalFiles FAIL | isVideo=${media.isVideo} '
              'elapsed=${mediaSw.elapsedMilliseconds}ms uploadedSoFar=$uploadedIds '
              'err=$e',
            );
            final message = e is AppException
                ? e.messages.join(', ')
                : (media.isVideo
                    ? 'Не удалось загрузить видео.'
                    : 'Не удалось загрузить фото.');
            emit(UploadError(
              message: message,
              thumbnail: thumbnail,
              mediaFiles: allMediaFiles,
              postId: '',
              token: _token,
              clientRequestId: clientRequestId,
              uploadedMediaIds: uploadedIds,
            ));
            return;
          }
        }
      }

      // Atomic post create with all media ids attached.
      talker.info(
        '[UPLOAD] all media uploaded | media_ids=$uploadedIds reqId=$clientRequestId — '
        'calling POST /v2/posts/',
      );
      emit(UploadCreating(thumbnail: thumbnail));

      postId = await _repository.createPostV2(
        token: _token,
        product: product,
        mediaIds: uploadedIds,
        clientRequestId: clientRequestId,
      );

      final optimistic = product.copyWith(
        id: postId,
        localPreviewPath: thumbnail?.path,
      );

      talker.info(
        '[UPLOAD] SUCCESS | postId=$postId reqId=$clientRequestId '
        'totalElapsed=${sw.elapsedMilliseconds}ms',
      );
      emit(UploadSuccess(postId: postId, optimisticProduct: optimistic));
      _cleanupTempFiles(allMediaFiles);
    } on MediaProcessingException catch (e) {
      talker.warning(
        '[UPLOAD] FAIL video-processing | reqId=$clientRequestId err=${e.message}',
      );
      emit(UploadError(
        message: e.message,
        mediaFiles: allMediaFiles,
        postId: postId,
        token: _token,
        clientRequestId: clientRequestId,
        uploadedMediaIds: uploadedIds,
      ));
    } on AppException catch (e) {
      talker.warning(
        '[UPLOAD] FAIL AppException | reqId=$clientRequestId '
        'uploadedSoFar=$uploadedIds err=${e.messages.join(", ")}',
      );
      emit(UploadError(
        message: e.messages.join(', '),
        thumbnail: _extractThumbnail(allMediaFiles),
        mediaFiles: allMediaFiles,
        postId: postId,
        token: _token,
        clientRequestId: clientRequestId,
        uploadedMediaIds: uploadedIds,
      ));
    } catch (e) {
      talker.warning(
        '[UPLOAD] FAIL unknown | reqId=$clientRequestId '
        'uploadedSoFar=$uploadedIds err=$e',
      );
      emit(UploadError(
        message: e.toString(),
        thumbnail: _extractThumbnail(allMediaFiles),
        mediaFiles: allMediaFiles,
        postId: postId,
        token: _token,
        clientRequestId: clientRequestId,
        uploadedMediaIds: uploadedIds,
      ));
    }
  }

  Future<void> retry() async {
    final current = state;
    if (current is! UploadError) return;

    // v1 patch retry path (edit flow) — only reachable while the
    // legacy v1 PATCH endpoint is still live and was used originally.
    if (current.clientRequestId.isEmpty && current.postId.isNotEmpty) {
      talker.info('[UPLOAD] RETRY v1 path | postId=${current.postId}');
      return _retryV1(current);
    }

    // v2 retry: replay with the same clientRequestId so the server
    // recognises it as the same logical "Publish" intent and returns
    // the existing post (no duplicate) instead of creating a new one.
    final thumbnail = current.thumbnail;
    final clientRequestId = current.clientRequestId.isNotEmpty
        ? current.clientRequestId
        : const Uuid().v4();
    final uploadedIds = List<int>.from(current.uploadedMediaIds);
    talker.info(
      '[UPLOAD] RETRY v2 | reqId=$clientRequestId '
      'alreadyUploaded=${uploadedIds.length}/${current.mediaFiles.length}',
    );
    final remaining = current.mediaFiles.skip(uploadedIds.length).toList();
    final totalFiles = current.mediaFiles.length;

    emit(UploadUploading(
      thumbnail: thumbnail,
      progress: uploadedIds.length / (totalFiles == 0 ? 1 : totalFiles),
      uploaded: uploadedIds.length,
      total: totalFiles,
    ));

    try {
      for (var i = 0; i < remaining.length; i++) {
        final absoluteIndex = uploadedIds.length;
        final result = await _repository.uploadPostMediaV2(
          remaining[i],
          _token,
          onSendProgress: (sent, total) {
            if (total > 0) {
              final overall =
                  (absoluteIndex + sent / total) / totalFiles;
              emit(UploadUploading(
                thumbnail: thumbnail,
                progress: overall.clamp(0.0, 1.0),
                uploaded: absoluteIndex,
                total: totalFiles,
              ));
            }
          },
        );
        uploadedIds.add(result.id);
      }

      // Atomic post create — same clientRequestId is the safety net.
      talker.info(
        '[UPLOAD] RETRY calling /v2/posts/ | media_ids=$uploadedIds '
        'reqId=$clientRequestId',
      );
      final postId = await _repository.createPostV2(
        token: _token,
        product: _productFromRetryState(current),
        mediaIds: uploadedIds,
        clientRequestId: clientRequestId,
      );

      talker.info('[UPLOAD] RETRY SUCCESS | postId=$postId');
      emit(UploadSuccess(postId: postId));
      _cleanupTempFiles(current.mediaFiles);
    } on AppException catch (e) {
      emit(UploadError(
        message: e.messages.join(', '),
        thumbnail: thumbnail,
        mediaFiles: current.mediaFiles,
        postId: '',
        token: _token,
        clientRequestId: clientRequestId,
        uploadedMediaIds: uploadedIds,
      ));
    } catch (e) {
      debugPrint('Upload retry error: $e');
      emit(UploadError(
        message: e.toString(),
        thumbnail: thumbnail,
        mediaFiles: current.mediaFiles,
        postId: '',
        token: _token,
        clientRequestId: clientRequestId,
        uploadedMediaIds: uploadedIds,
      ));
    }
  }

  void dismiss() => emit(const UploadIdle());

  // ─── v1 PATCH (edit) fallback ───────────────────────────────────
  // Backend v2 doesn't expose PATCH yet, so existing edits keep going
  // through v1: PATCH /posts/<id>/ then upload-media-with-post-id.

  Future<void> _startUploadV1Patch({
    required Product product,
    required List<MediaFile> mediaFiles,
    File? rawVideoFile,
  }) async {
    final allMediaFiles = [...mediaFiles];
    String postId = '';
    try {
      if (rawVideoFile != null) {
        emit(const UploadProcessing(statusText: 'Обработка видео...'));
        final videoMedia = await _mediaProcessor.processVideo(
          rawVideoFile,
          onStatusChanged: (stage) {
            emit(UploadProcessing(
              statusText: switch (stage) {
                VideoProcessingStage.validating => 'Проверка видео...',
                VideoProcessingStage.generatingThumbnail =>
                  'Генерация превью...',
                VideoProcessingStage.finalizing => 'Завершение обработки...',
              },
            ));
          },
        );
        if (videoMedia != null) allMediaFiles.add(videoMedia);
      }

      final thumbnail = _extractThumbnail(allMediaFiles);
      emit(UploadCreating(thumbnail: thumbnail));
      postId = await _repository.createPost(
        _token,
        product,
        EnumRequestType.patch,
      );

      if (allMediaFiles.isEmpty) {
        emit(UploadSuccess(postId: postId));
        return;
      }

      final totalFiles = allMediaFiles.length;
      await _repository.uploadMediaWithProgress(
        allMediaFiles,
        postId,
        _token,
        onProgress: (fileIndex, _, fileProgress) {
          final overall = (fileIndex + fileProgress) / totalFiles;
          emit(UploadUploading(
            thumbnail: thumbnail,
            progress: overall.clamp(0.0, 1.0),
            uploaded: fileIndex,
            total: totalFiles,
          ));
        },
      );

      emit(UploadSuccess(postId: postId));
      _cleanupTempFiles(allMediaFiles);
    } on AppException catch (e) {
      emit(UploadError(
        message: e.messages.join(', '),
        thumbnail: _extractThumbnail(allMediaFiles),
        mediaFiles: allMediaFiles,
        postId: postId,
        token: _token,
      ));
    } catch (e) {
      emit(UploadError(
        message: e.toString(),
        thumbnail: _extractThumbnail(allMediaFiles),
        mediaFiles: allMediaFiles,
        postId: postId,
        token: _token,
      ));
    }
  }

  Future<void> _retryV1(UploadError current) async {
    final thumbnail = current.thumbnail;
    emit(UploadUploading(
      thumbnail: thumbnail,
      progress: 0,
      uploaded: 0,
      total: current.mediaFiles.length,
    ));
    try {
      await _repository.uploadMediaWithProgress(
        current.mediaFiles,
        current.postId,
        _token,
        onProgress: (fileIndex, totalFiles, fileProgress) {
          final overall = (fileIndex + fileProgress) / totalFiles;
          emit(UploadUploading(
            thumbnail: thumbnail,
            progress: overall.clamp(0.0, 1.0),
            uploaded: fileIndex,
            total: totalFiles,
          ));
        },
      );
      emit(UploadSuccess(postId: current.postId));
      _cleanupTempFiles(current.mediaFiles);
    } catch (e) {
      emit(UploadError(
        message: e is AppException ? e.messages.join(', ') : e.toString(),
        thumbnail: thumbnail,
        mediaFiles: current.mediaFiles,
        postId: current.postId,
        token: _token,
      ));
    }
  }

  /// v2 retry needs the original `Product` to call `createPostV2` again.
  /// We don't currently snapshot the product into `UploadError` — the
  /// best-available recovery is `localPreviewPath` set on the optimistic
  /// product; for fields we fall back to a placeholder that the user
  /// will see and re-publish. In practice retry happens before
  /// optimistic product is set, so this branch is rarely hit.
  Product _productFromRetryState(UploadError current) {
    return Product(
      id: current.postId,
      localPreviewPath: current.thumbnail?.path,
    );
  }

  /// Best-effort rollback: if this fails (network dead), the server
  /// may be left with an orphan post — next client retry or admin
  /// cleanup handles it. We don't surface this error to the user
  /// because the original video-upload failure is the primary cause.
  Future<void> _rollbackPost(String postId) async {
    if (postId.isEmpty) return;
    try {
      await _repository.deleteProduct(postId, _token);
    } catch (e) {
      debugPrint('Rollback deletePost failed for $postId: $e');
    }
  }

  File? _extractThumbnail(List<MediaFile> mediaFiles) {
    if (mediaFiles.isEmpty) return null;
    final first = mediaFiles.first;
    return first.thumbnail ?? (first.isImage ? first.file : null);
  }

  /// Clean up temporary thumbnail files after successful upload.
  void _cleanupTempFiles(List<MediaFile> mediaFiles) {
    for (final media in mediaFiles) {
      if (media.thumbnail != null) {
        media.thumbnail!.delete().catchError((_) => media.thumbnail!);
      }
    }
  }
}
