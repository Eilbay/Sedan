import 'package:flutter_test/flutter_test.dart';
import 'package:optombai/data/models/posts/post_model.dart';

void main() {
  group('PostImage', () {
    test('reads is_video flag from server', () {
      final img = PostImage.fromJson({
        'id': 1,
        'image': 'https://example.com/a.mp4',
        'is_video': true,
      });
      expect(img.isVideo, isTrue);
      expect(img.serverIsVideo, isTrue);
    });

    test('server is_video=false overrides extension heuristic', () {
      final img = PostImage.fromJson({
        'id': 1,
        'image': 'https://example.com/clip.mp4',
        'is_video': false,
      });
      expect(img.isVideo, isFalse);
    });

    test('falls back to extension when is_video is missing', () {
      final img = PostImage.fromJson({
        'id': 1,
        'image': 'https://example.com/clip.MOV',
      });
      expect(img.isVideo, isTrue);
    });

    test('treats known image extensions as images regardless of path', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic']) {
        final img = PostImage.fromJson({
          'id': 1,
          'image': 'https://example.com/a.$ext',
        });
        expect(img.isVideo, isFalse, reason: ext);
      }
    });

    test('displayUrlOrNull returns null for video without cover', () {
      final img = PostImage.fromJson({
        'id': 1,
        'image': 'https://example.com/a.mp4',
        'is_video': true,
      });
      expect(img.displayUrlOrNull, isNull);
    });

    test('displayUrlOrNull returns cover_medium when present', () {
      final img = PostImage.fromJson({
        'id': 1,
        'image': 'https://example.com/a.mp4',
        'is_video': true,
        'cover_medium': 'https://example.com/a.webp',
      });
      expect(img.displayUrlOrNull, 'https://example.com/a.webp');
    });

    test('displayUrlOrNull prefers cover_medium over cover', () {
      final img = PostImage.fromJson({
        'id': 1,
        'image': 'https://example.com/a.mp4',
        'is_video': true,
        'cover': 'https://example.com/a.jpg',
        'cover_medium': 'https://example.com/a.webp',
      });
      expect(img.displayUrlOrNull, 'https://example.com/a.webp');
    });

    test('displayUrlOrNull for image returns the image URL', () {
      final img = PostImage.fromJson({
        'id': 1,
        'image': 'https://example.com/a.jpg',
      });
      expect(img.displayUrlOrNull, 'https://example.com/a.jpg');
    });

    test('legacy displayUrl still returns .mp4 URL for backward compat', () {
      final img = PostImage.fromJson({
        'id': 1,
        'image': 'https://example.com/a.mp4',
        'is_video': true,
      });
      // Non-null getter returns raw URL so legacy call-sites do not crash.
      // Prefer displayUrlOrNull in new UI code.
      expect(img.displayUrl, 'https://example.com/a.mp4');
    });
  });

  group('Product.previewUrl', () {
    Map<String, dynamic> _img(
      String url, {
      bool? isVideo,
      String? coverMedium,
    }) {
      return {
        'id': 1,
        'image': url,
        if (isVideo != null) 'is_video': isVideo,
        if (coverMedium != null) 'cover_medium': coverMedium,
      };
    }

    test('returns first image URL when first is a photo', () {
      final p = Product.fromJson({
        'id': 'x',
        'name': '',
        'description': '',
        'images_post': [
          _img('https://cdn/a.jpg'),
          _img('https://cdn/b.mp4', isVideo: true),
        ],
      });
      expect(p.previewUrl, 'https://cdn/a.jpg');
    });

    test('returns video cover when only video present with cover', () {
      final p = Product.fromJson({
        'id': 'x',
        'name': '',
        'description': '',
        'images_post': [
          _img('https://cdn/a.mp4', isVideo: true, coverMedium: 'https://cdn/a.webp'),
        ],
      });
      expect(p.previewUrl, 'https://cdn/a.webp');
    });

    test('falls back to cover_image when first is video without cover', () {
      final p = Product.fromJson({
        'id': 'x',
        'name': '',
        'description': '',
        'cover_image': 'https://cdn/auto.jpg',
        'images_post': [
          _img('https://cdn/a.mp4', isVideo: true),
        ],
      });
      expect(p.previewUrl, 'https://cdn/auto.jpg');
    });

    test('uses sibling photo when first is video without cover', () {
      final p = Product.fromJson({
        'id': 'x',
        'name': '',
        'description': '',
        'images_post': [
          _img('https://cdn/a.mp4', isVideo: true),
          _img('https://cdn/b.jpg'),
        ],
      });
      // First image has no cover yet, but we fall back to the photo.
      expect(p.previewUrl, 'https://cdn/b.jpg');
    });

    test('returns null when no media is available', () {
      final p = Product.fromJson({
        'id': 'x',
        'name': '',
        'description': '',
        'images_post': [],
      });
      expect(p.previewUrl, isNull);
    });

    test('localPreviewPath is preserved by copyWith (optimistic insert path)', () {
      final p = Product(id: 'x');
      final optimistic = p.copyWith(localPreviewPath: '/tmp/thumb.jpg');
      expect(optimistic.localPreviewPath, '/tmp/thumb.jpg');
      expect(optimistic.id, 'x');
    });

    test('localPreviewPath does not leak into JSON round-trip', () {
      final p = Product(id: 'x', localPreviewPath: '/tmp/thumb.jpg');
      // Round-trip through fromJson: server never sees localPreviewPath, so it
      // must be null after deserialization.
      final json = p.toJson();
      expect(json.containsKey('localPreviewPath'), isFalse);
    });
  });
}
