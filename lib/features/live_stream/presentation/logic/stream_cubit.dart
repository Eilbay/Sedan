import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/error/stream_log_file.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/domain/repositories/live_stream_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'stream_state.dart';

class StreamCubit extends Cubit<StreamState> {
  StreamCubit({
    required SharedPreferences preferences,
    required LiveStreamRepository repository,
  })  : _repository = repository,
        super(const StreamState()) {
    _preferences = preferences;
    _restoreStreamsFromCache();
  }

  late final SharedPreferences _preferences;
  static const String _streamsCacheKey = 'cached_streams_payload_v1';
  static const Duration _streamsMinSyncInterval = Duration(seconds: 10);
  static const String _legacyActiveBroadcastKey = 'active_broadcast_stream_id';
  static const String _pendingBroadcastsKey = 'pending_broadcast_stream_ids_v2';
  bool _isFetchingStreams = false;
  bool _isCreatingStream = false;
  DateTime? _lastStreamsSyncAt;
  Completer<void>? _pendingCleanupCompleter;

  String get token => _preferences.getString(TOKEN_KEY) ?? "";

  final LiveStreamRepository _repository;

  LiveStreamRepository get repository => _repository;

  void _restoreStreamsFromCache() {
    final cached = _preferences.getString(_streamsCacheKey);
    if (cached == null || cached.isEmpty) return;

    try {
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) return;

      final streams = deduplicateStreamsByOwner(Streams.fromJson(decoded));
      // Cached data stays visible while BottomNav/WatchStreamPage trigger a
      // fresh request. Keeping status=initial used to hide this payload behind
      // an endless loading screen whenever that request failed.
      emit(
        state.copyWith(
          status: StreamStatus.success,
          streams: streams,
        ),
      );
    } catch (_) {}
  }

  Future<void> _cacheStreams(Streams streams) async {
    try {
      await _preferences.setString(
        _streamsCacheKey,
        jsonEncode(streams.toJson()),
      );
    } catch (_) {}
  }

  Future<StreamModel?> createStream({String? ownerId}) async {
    if (_isCreatingStream) {
      StreamLogFile.log(
        '[LS_CUBIT] createStream ignored: request already in flight',
        isWarning: true,
      );
      return null;
    }

    _isCreatingStream = true;
    StreamLogFile.log('[LS_CUBIT] createStream requested');
    emit(state.copyWith(status: StreamStatus.loading));

    try {
      await endLeftoverBroadcast();
      await _endExistingLiveStreamsForOwner(ownerId);

      final stream = await _repository.createStream(token: token);

      if (stream != null) {
        // Persist immediately after POST, before navigation. If the widget is
        // removed before CreateStreamPage mounts, startup cleanup can still
        // close this server row.
        setActiveBroadcast(stream.id);
        emit(
          state.copyWith(
            status: StreamStatus.success,
            stream: stream,
          ),
        );

        return stream;
      }

      emit(state.copyWith(status: StreamStatus.error));
      return null;
    } catch (e, st) {
      StreamLogFile.log('[LS_CUBIT] createStream error: $e', isWarning: true);
      debugPrint(st.toString());
      emit(state.copyWith(status: StreamStatus.error));
      rethrow;
    } finally {
      _isCreatingStream = false;
    }
  }

  Future<void> endStream(String streamId) async {
    StreamLogFile.log('[LS_CUBIT] endStream called for $streamId');

    // Remove from local list immediately so viewers see it disappear.
    removeStream(streamId);

    final ended = await _endRemoteStream(streamId);

    if (ended != null) {
      // Clear only after confirmed API success so that if the call failed
      // (network down, etc.) endLeftoverBroadcast() can retry on next launch.
      clearActiveBroadcast(streamId);
      StreamLogFile.log('[LS_CUBIT] endStream API success for $streamId');
    } else {
      StreamLogFile.log(
        '[LS_CUBIT] endStream API returned null for $streamId — '
        'activeBroadcast key kept for retry on next launch.',
        isWarning: true,
      );
    }

    emit(
      state.copyWith(
        status: StreamStatus.success,
        stream: ended ?? state.stream,
      ),
    );
  }

  /// Mark a stream as banned for this session and remove it from the list.
  /// The stream won't re-appear even after subsequent list refreshes.
  void addBannedStream(String streamId) {
    final updated = Set<String>.from(state.bannedStreamIds)..add(streamId);
    emit(state.copyWith(bannedStreamIds: updated));
    removeStream(streamId);
  }

  /// Remove a stream from the local list (e.g. when it ends).
  void removeStream(String streamId) {
    final currentStreams = state.streams;
    if (currentStreams == null) {
      debugPrint('[StreamCubit] removeStream: no streams list to remove from');
      return;
    }

    final beforeCount = currentStreams.results.length;
    final updated =
        currentStreams.results.where((s) => s.id != streamId).toList();

    debugPrint(
        '[StreamCubit] removeStream $streamId: $beforeCount -> ${updated.length} streams');

    final newStreams = Streams(
      next: currentStreams.next,
      previous: currentStreams.previous,
      results: updated,
    );

    unawaited(_cacheStreams(newStreams));
    emit(state.copyWith(streams: newStreams));
  }

  Future<bool> startStream(String streamId) async {
    StreamLogFile.log('[LS_CUBIT] startStream requested for $streamId');
    try {
      final started = await _repository.startStream(
        token: token,
        streamId: streamId,
      );

      if (started != null) {
        emit(
          state.copyWith(
            status: StreamStatus.success,
            stream: started,
          ),
        );
        return true;
      }

      return false;
    } catch (e, st) {
      StreamLogFile.log('[LS_CUBIT] startStream error: $e', isWarning: true);
      debugPrint(st.toString());
      return false;
    }
  }

  /// Fire-and-forget keepalive ping for the owner's active broadcast.
  /// Failures are logged but never surfaced — a missed heartbeat just falls
  /// back to the server's coarser `started_at`-based liveness check.
  Future<void> sendHeartbeat(String streamId) async {
    try {
      await _repository.sendHeartbeat(token: token, streamId: streamId);
    } catch (e) {
      StreamLogFile.log('[LS_CUBIT] sendHeartbeat error: $e', isWarning: true);
    }
  }

  Future<void> getStreams({bool force = false}) async {
    if (_isFetchingStreams) return;
    if (token.isEmpty) {
      emit(state.copyWith(status: StreamStatus.error));
      return;
    }

    final now = DateTime.now();
    final hasStateData = state.streams != null;

    if (!force &&
        hasStateData &&
        _lastStreamsSyncAt != null &&
        now.difference(_lastStreamsSyncAt!) < _streamsMinSyncInterval) {
      return;
    }

    _isFetchingStreams = true;

    try {
      if (!hasStateData) {
        emit(state.copyWith(status: StreamStatus.loading));
      }

      final response = await _repository.getStreams(token: token);
      _lastStreamsSyncAt = DateTime.now();

      if (response != null) {
        final streams = deduplicateStreamsByOwner(response);
        unawaited(_cacheStreams(streams));
        emit(state.copyWith(status: StreamStatus.success, streams: streams));
      } else if (!hasStateData) {
        emit(state.copyWith(status: StreamStatus.error));
      }
    } catch (e, st) {
      StreamLogFile.log(
        '[LS_CUBIT] getStreams FAILED force=$force hasStateData=$hasStateData: $e\n$st',
        isWarning: true,
      );
      if (!hasStateData) {
        emit(state.copyWith(status: StreamStatus.error));
      }
    } finally {
      _isFetchingStreams = false;
    }
  }

  void setCurrentIndex(int index) {
    if (index == state.currentIndex) return;

    emit(state.copyWith(currentIndex: index));
    _saveLastViewedStreamIndex(index);
  }

  void _saveLastViewedStreamIndex(int index) {
    _preferences.setInt('last_viewed_stream_index', index);
  }

  int getLastViewedStreamIndex() {
    return _preferences.getInt('last_viewed_stream_index') ?? 0;
  }

  /// Save the stream ID being broadcast so it can be ended on next app launch
  /// if the app was killed without proper cleanup.
  void setActiveBroadcast(String streamId) {
    if (streamId.isEmpty) return;
    final ids = _readPendingBroadcastIds()..add(streamId);
    _writePendingBroadcastIds(ids);
  }

  /// Clear only the stream that was confirmed ended. Removing a single global
  /// marker allowed a late response for an old stream to erase a newer one's
  /// crash-recovery marker.
  void clearActiveBroadcast(String streamId) {
    final ids = _readPendingBroadcastIds()..remove(streamId);
    _writePendingBroadcastIds(ids);
  }

  /// End any leftover stream from a previous session that wasn't properly closed.
  /// Only clears the stored ID if the API call succeeds, so failed calls
  /// are retried automatically on the next app launch.
  Future<void> endLeftoverBroadcast() async {
    final existingCleanup = _pendingCleanupCompleter;
    if (existingCleanup != null) {
      return existingCleanup.future;
    }

    final completer = Completer<void>();
    _pendingCleanupCompleter = completer;

    try {
      final streamIds = _readPendingBroadcastIds().toList(growable: false);
      for (final streamId in streamIds) {
        debugPrint(
            '[StreamCubit] Found pending broadcast: $streamId, ending...');
        final result = await _endRemoteStream(streamId);
        if (result != null) {
          debugPrint('[StreamCubit] Pending broadcast $streamId ended.');
          clearActiveBroadcast(streamId);
        } else {
          debugPrint(
            '[StreamCubit] Failed to end pending broadcast $streamId — '
            'will retry later.',
          );
        }
      }
    } finally {
      _pendingCleanupCompleter = null;
      completer.complete();
    }
  }

  Future<void> _endExistingLiveStreamsForOwner(String? ownerId) async {
    final normalizedOwnerId = ownerId?.trim() ?? '';
    if (normalizedOwnerId.isEmpty || token.isEmpty) return;

    final streams = await _repository.getStreams(token: token);
    if (streams == null) return;

    final existingIds = streams.results
        .where((stream) =>
            stream.isLive && stream.owner.id.trim() == normalizedOwnerId)
        .map((stream) => stream.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final streamId in existingIds) {
      StreamLogFile.log(
        '[LS_CUBIT] ending existing live stream before create: $streamId',
      );
      final ended = await _endRemoteStream(streamId);
      if (ended != null) {
        clearActiveBroadcast(streamId);
      }
    }
  }

  Future<StreamModel?> _endRemoteStream(String streamId) async {
    StreamModel? ended;
    for (var attempt = 1; attempt <= 2; attempt++) {
      ended = await _repository.endStream(token: token, streamId: streamId);
      if (ended != null) return ended;
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    return null;
  }

  Set<String> _readPendingBroadcastIds() {
    final ids = <String>{};
    final encoded = _preferences.getString(_pendingBroadcastsKey);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          ids.addAll(
            decoded
                .map((value) => value.toString())
                .where((id) => id.isNotEmpty),
          );
        }
      } catch (_) {}
    }

    final legacyId = _preferences.getString(_legacyActiveBroadcastKey);
    if (legacyId != null && legacyId.isNotEmpty) ids.add(legacyId);
    return ids;
  }

  void _writePendingBroadcastIds(Set<String> ids) {
    if (ids.isEmpty) {
      unawaited(_preferences.remove(_pendingBroadcastsKey));
    } else {
      final sorted = ids.toList()..sort();
      unawaited(
          _preferences.setString(_pendingBroadcastsKey, jsonEncode(sorted)));
    }
    // Migrate away from the old single-ID key after every write.
    unawaited(_preferences.remove(_legacyActiveBroadcastKey));
  }
}
