import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/data/models/posts/post_model.dart';

sealed class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadIdle extends UploadState {
  const UploadIdle();
}

class UploadProcessing extends UploadState {
  final String statusText;
  const UploadProcessing({required this.statusText});
  @override
  List<Object?> get props => [statusText];
}

class UploadCreating extends UploadState {
  final File? thumbnail;

  const UploadCreating({this.thumbnail});

  @override
  List<Object?> get props => [thumbnail];
}

class UploadUploading extends UploadState {
  final File? thumbnail;
  final double progress;
  final int uploaded;
  final int total;
  // Set on the first UploadUploading emission, right after the post is
  // created on the server. Lets the UI insert a placeholder card in the
  // feed while the media files finish uploading.
  final Product? optimisticProduct;

  const UploadUploading({
    this.thumbnail,
    required this.progress,
    required this.uploaded,
    required this.total,
    this.optimisticProduct,
  });

  @override
  List<Object?> get props =>
      [thumbnail, progress, uploaded, total, optimisticProduct];
}

class UploadSuccess extends UploadState {
  final String postId;
  // Populated when the cubit has enough info to hand a freshly-created
  // Product (with local thumbnails) to the feed for optimistic rendering.
  final Product? optimisticProduct;

  const UploadSuccess({required this.postId, this.optimisticProduct});

  @override
  List<Object?> get props => [postId, optimisticProduct];
}

class UploadError extends UploadState {
  final String message;
  final File? thumbnail;
  final List<MediaFile> mediaFiles;
  final String postId;
  final String token;
  // Non-empty when the post was created but later rolled back
  // (e.g. video upload failed). UI uses this to remove the
  // optimistic card from the feed. Retry is not possible.
  final String rolledBackPostId;

  // v2 retry resume state. When the upload failed AFTER some media
  // were already uploaded, these capture what's already on the server
  // so retry() can pick up where it left off instead of starting over.
  final String clientRequestId;
  final List<int> uploadedMediaIds;

  const UploadError({
    required this.message,
    this.thumbnail,
    required this.mediaFiles,
    required this.postId,
    required this.token,
    this.rolledBackPostId = '',
    this.clientRequestId = '',
    this.uploadedMediaIds = const [],
  });

  @override
  List<Object?> get props => [
        message,
        thumbnail,
        mediaFiles,
        postId,
        token,
        rolledBackPostId,
        clientRequestId,
        uploadedMediaIds,
      ];
}
