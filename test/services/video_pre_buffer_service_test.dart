import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optombai/services/i_player_factory.dart';
import 'package:optombai/services/video_pre_buffer_service.dart';

import '../helpers/test_utils.dart';

class MockPlayerFactory extends Mock implements IPlayerFactory {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPlayerFactory mockFactory;
  late VideoPreBufferService service;

  setUp(() {
    mockFactory = MockPlayerFactory();
    service = VideoPreBufferService(playerFactory: mockFactory);
  });

  tearDown(() {
    service.dispose();
  });

  // ---------------------------------------------------------------------------
  // enqueue
  // ---------------------------------------------------------------------------
  group('enqueue', () {
    test('is no-op after dispose', () async {
      service.dispose();
      // Should not throw and not call factory
      service.enqueue(['https://a.com/1.mp4']);
      await flushAsync();
      verifyNever(() => mockFactory.createPreBufferPlayer(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // take
  // ---------------------------------------------------------------------------
  group('take', () {
    test('returns null for unknown URL', () {
      expect(service.take('https://unknown.com/x.mp4'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // pause / resume
  // ---------------------------------------------------------------------------
  group('pause / resume', () {
    test('pause prevents queue processing', () async {
      service.pause();
      service.enqueue(['https://a.com/1.mp4', 'https://a.com/2.mp4']);
      await flushAsync();

      // Nothing should have been created
      verifyNever(() => mockFactory.createPreBufferPlayer(any()));
      expect(service.take('https://a.com/1.mp4'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // cancel
  // ---------------------------------------------------------------------------
  group('cancel', () {
    test('no-op for unknown URL', () {
      service.cancel('https://unknown.com/x.mp4');
    });
  });

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------
  group('dispose', () {
    test('makes take return null for all URLs', () {
      service.dispose();
      expect(service.take('https://a.com/1.mp4'), isNull);
    });

    test('double dispose is safe', () {
      service.dispose();
      service.dispose();
    });
  });
}
