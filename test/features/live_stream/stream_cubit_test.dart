import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/domain/repositories/live_stream_repository.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLiveStreamRepository extends Mock implements LiveStreamRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (_) async => Directory.systemTemp.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  group('deduplicateStreamsByOwner', () {
    test('keeps the newest stream for each owner', () {
      final old = _stream(
        id: 'old',
        ownerId: 'owner-a',
        startedAt: DateTime.utc(2026, 7, 11, 10),
      );
      final other = _stream(
        id: 'other',
        ownerId: 'owner-b',
        startedAt: DateTime.utc(2026, 7, 11, 11),
      );
      final newest = _stream(
        id: 'new',
        ownerId: 'owner-a',
        startedAt: DateTime.utc(2026, 7, 11, 12),
      );

      final result = deduplicateStreamsByOwner(
        Streams(next: null, previous: null, results: [old, other, newest]),
      );

      expect(result.results.map((stream) => stream.id), ['new', 'other']);
    });

    test('does not merge streams whose owner id is missing', () {
      final result = deduplicateStreamsByOwner(
        Streams(
          next: null,
          previous: null,
          results: [
            _stream(id: 'one', ownerId: ''),
            _stream(id: 'two', ownerId: ''),
          ],
        ),
      );

      expect(result.results, hasLength(2));
    });
  });

  group('StreamCubit broadcast lifecycle', () {
    late _MockLiveStreamRepository repository;
    late SharedPreferences preferences;
    late StreamCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'TOKEN_KEY': 'token'});
      preferences = await SharedPreferences.getInstance();
      repository = _MockLiveStreamRepository();
      cubit = StreamCubit(
        preferences: preferences,
        repository: repository,
      );
    });

    tearDown(() => cubit.close());

    test('coalesces rapid create requests into one POST', () async {
      final response = Completer<StreamModel?>();
      when(() => repository.createStream(token: 'token'))
          .thenAnswer((_) => response.future);

      final first = cubit.createStream();
      final second = cubit.createStream();
      response.complete(_stream(id: 'created', ownerId: 'me'));

      expect(await first, isNotNull);
      expect(await second, isNull);
      verify(() => repository.createStream(token: 'token')).called(1);
    });

    test('ending an old stream does not erase a newer pending marker',
        () async {
      cubit.setActiveBroadcast('old');
      cubit.setActiveBroadcast('new');
      when(() => repository.endStream(token: 'token', streamId: 'old'))
          .thenAnswer((_) async => _stream(id: 'old', ownerId: 'me'));

      await cubit.endStream('old');

      expect(_pendingIds(preferences), {'new'});
    });

    test('failed end remains pending for a later retry', () async {
      cubit.setActiveBroadcast('pending');
      when(() => repository.endStream(token: 'token', streamId: 'pending'))
          .thenAnswer((_) async => null);

      await cubit.endStream('pending');

      expect(_pendingIds(preferences), {'pending'});
      verify(() => repository.endStream(
            token: 'token',
            streamId: 'pending',
          )).called(2);
    });

    test('restores cached streams as visible success state', () async {
      await cubit.close();
      final cached = Streams(
        next: null,
        previous: null,
        results: [_stream(id: 'cached', ownerId: 'owner')],
      );
      await preferences.setString(
        'cached_streams_payload_v1',
        jsonEncode(cached.toJson()),
      );

      cubit = StreamCubit(
        preferences: preferences,
        repository: repository,
      );

      expect(cubit.state.status, StreamStatus.success);
      expect(cubit.state.streams?.results.single.id, 'cached');
    });
  });
}

Set<String> _pendingIds(SharedPreferences preferences) {
  final raw = preferences.getString('pending_broadcast_stream_ids_v2');
  if (raw == null) return {};
  return (jsonDecode(raw) as List).map((value) => value.toString()).toSet();
}

StreamModel _stream({
  required String id,
  required String ownerId,
  DateTime? startedAt,
}) {
  return StreamModel(
    id: id,
    type: 'live',
    title: id,
    description: '',
    isLive: true,
    owner: Owner(id: ownerId, username: ownerId),
    startedAt: startedAt,
    endedAt: null,
    streamKey: 'key-$id',
    hlsUrl: '',
    webrtc: Webrtc(
      apiUrl: '',
      api: WebrtcApi(play: '', publish: ''),
      app: 'live',
      stream: id,
      url: 'webrtc://example.com/live/$id',
    ),
    chat: Chat(wsUrl: '', wsUrlWithTokenTemplate: ''),
    viewers: 0,
  );
}
