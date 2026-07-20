import 'package:flutter_test/flutter_test.dart';
import 'package:optombai/services/i_player_factory.dart';
import 'package:optombai/services/video_player_factory.dart';
import 'package:video_player/video_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPlayerFactory', () {
    late IPlayerFactory factory;

    setUp(() {
      factory = VideoPlayerFactory();
    });

    test('createReelPlayer pre-seeds isLooping=true in value', () {
      final c = factory.createReelPlayer('https://example.com/x.m3u8');
      // Pre-initialize state — actual platform looping is applied on initialize().
      expect(c, isA<VideoPlayerController>());
      expect(c.value.isLooping, isTrue);
      c.dispose();
    });

    test('createReelPlayer sets dataSource correctly', () {
      final c = factory.createReelPlayer('https://example.com/x.m3u8');
      expect(c.dataSource, 'https://example.com/x.m3u8');
      c.dispose();
    });

    test('createPreviewPlayer disables looping (single-shot)', () {
      final c = factory.createPreviewPlayer('https://example.com/x.mp4');
      expect(c.value.isLooping, isFalse);
      c.dispose();
    });

    test('createViewerPlayer disables looping', () {
      final c = factory.createViewerPlayer('https://example.com/x.mp4');
      expect(c.value.isLooping, isFalse);
      c.dispose();
    });

    test('createPreBufferPlayer pre-seeds isLooping=true and volume=0', () {
      final c = factory.createPreBufferPlayer('https://example.com/x.m3u8');
      expect(c, isA<VideoPlayerController>());
      expect(c.value.isLooping, isTrue);
      expect(c.value.volume, 0);
      c.dispose();
    });

    test('createReelPlayer returns distinct instances per call', () {
      final a = factory.createReelPlayer('https://example.com/x.m3u8');
      final b = factory.createReelPlayer('https://example.com/x.m3u8');
      expect(identical(a, b), isFalse);
      a.dispose();
      b.dispose();
    });
  });
}
