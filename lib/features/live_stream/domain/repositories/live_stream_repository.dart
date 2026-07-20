import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/data/models/stream_ban_model.dart';

abstract class LiveStreamRepository {
  Future<StreamModel?> createStream({required String token});

  Future<StreamModel?> startStream({
    required String token,
    required String streamId,
  });

  Future<StreamModel?> endStream(
      {required String token, required String streamId});

  /// Owner-only keepalive ping sent periodically while broadcasting.
  Future<void> sendHeartbeat({required String token, required String streamId});

  Future<Streams?> getStreams({required String token});

  Future<StreamModel?> getStream({required String streamId});

  /// Check if a specific stream is still live.
  Future<bool> isStreamLive({required String streamId});

  Future<StreamBanModel?> banUser({
    required String token,
    required String streamId,
    required String userId,
    int? minutes,
    String? until,
    String? reason,
  });

  Future<void> unbanUser({
    required String token,
    required String streamId,
    required String userId,
  });
}
