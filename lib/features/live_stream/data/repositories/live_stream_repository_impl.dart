import 'package:optombai/features/live_stream/data/data_sources/stream_remote_data_source.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/data/models/stream_ban_model.dart';
import 'package:optombai/features/live_stream/domain/repositories/live_stream_repository.dart';

class LiveStreamRepositoryImpl implements LiveStreamRepository {
  const LiveStreamRepositoryImpl({required this.remoteDataSource});

  final StreamRemoteDataSource remoteDataSource;

  @override
  Future<StreamModel?> createStream({required String token}) async {
    return await remoteDataSource.createStream(token: token);
  }

  @override
  Future<StreamModel?> startStream(
      {required String token, required String streamId}) async {
    return await remoteDataSource.startStream(token: token, streamId: streamId);
  }

  @override
  Future<StreamModel?> endStream(
      {required String token, required String streamId}) async {
    return await remoteDataSource.endStream(token: token, streamId: streamId);
  }

  @override
  Future<void> sendHeartbeat(
      {required String token, required String streamId}) async {
    await remoteDataSource.sendHeartbeat(token: token, streamId: streamId);
  }

  @override
  Future<Streams?> getStreams({required String token}) async {
    return await remoteDataSource.getStreams(token: token);
  }

  @override
  Future<StreamModel?> getStream({required String streamId}) async {
    return await remoteDataSource.getStream(streamId: streamId);
  }

  @override
  Future<bool> isStreamLive({required String streamId}) async {
    return await remoteDataSource.isStreamLive(streamId: streamId);
  }

  @override
  Future<StreamBanModel?> banUser({
    required String token,
    required String streamId,
    required String userId,
    int? minutes,
    String? until,
    String? reason,
  }) async {
    return await remoteDataSource.banUser(
      token: token,
      streamId: streamId,
      userId: userId,
      minutes: minutes,
      until: until,
      reason: reason,
    );
  }

  @override
  Future<void> unbanUser({
    required String token,
    required String streamId,
    required String userId,
  }) async {
    await remoteDataSource.unbanUser(
      token: token,
      streamId: streamId,
      userId: userId,
    );
  }
}
