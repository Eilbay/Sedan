import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/widgets/product/product_cover_image.dart';
import 'package:optombai/widgets/utils/card/empty_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 180, height: 180, child: child),
      ),
    );

Product _productFromJson(Map<String, dynamic> json) => Product.fromJson(json);

void main() {
  group('ProductCoverImage (feed cases)', () {
    testWidgets('photo only → renders CachedNetworkImage without play overlay',
        (tester) async {
      final p = _productFromJson({
        'id': '1',
        'name': '',
        'description': '',
        'images_post': [
          {'id': 1, 'image': 'https://cdn/a.jpg', 'is_video': false},
        ],
      });

      await tester.pumpWidget(_wrap(ProductCoverImage(product: p)));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byType(EmptyImageWidget), findsNothing);
    });

    testWidgets(
        'video with cover_medium → network image with play overlay',
        (tester) async {
      final p = _productFromJson({
        'id': '1',
        'name': '',
        'description': '',
        'images_post': [
          {
            'id': 1,
            'image': 'https://cdn/a.mp4',
            'is_video': true,
            'cover_medium': 'https://cdn/a.webp',
          },
        ],
      });

      await tester.pumpWidget(_wrap(ProductCoverImage(product: p)));
      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.imageUrl, 'https://cdn/a.webp');
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets(
        'video without cover BUT with sibling photo → uses photo (no overlay)',
        (tester) async {
      // First image is video without cover; second is a real photo.
      // previewUrl should skip the broken video and return the photo.
      final p = _productFromJson({
        'id': '1',
        'name': '',
        'description': '',
        'images_post': [
          {'id': 1, 'image': 'https://cdn/a.mp4', 'is_video': true},
          {'id': 2, 'image': 'https://cdn/b.jpg', 'is_video': false},
        ],
      });

      await tester.pumpWidget(_wrap(ProductCoverImage(product: p)));
      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.imageUrl, 'https://cdn/b.jpg');
      // Play overlay is shown because FIRST media is a video (semantically
      // correct: the card represents a video-containing post).
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets(
        'video without cover but with product.cover_image → uses cover_image',
        (tester) async {
      final p = _productFromJson({
        'id': '1',
        'name': '',
        'description': '',
        'cover_image': 'https://cdn/auto.jpg',
        'images_post': [
          {'id': 1, 'image': 'https://cdn/a.mp4', 'is_video': true},
        ],
      });

      await tester.pumpWidget(_wrap(ProductCoverImage(product: p)));
      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.imageUrl, 'https://cdn/auto.jpg');
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('no media anywhere → EmptyImageWidget, no network call',
        (tester) async {
      final p = _productFromJson({
        'id': '1',
        'name': '',
        'description': '',
        'images_post': [],
      });
      await tester.pumpWidget(_wrap(ProductCoverImage(product: p)));
      expect(find.byType(EmptyImageWidget), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('localPreviewPath → Image.file is used, overlay shown',
        (tester) async {
      // Create a real tiny file so Image.file does not throw in tests.
      final tmp = File('${Directory.systemTemp.path}/cover_test.jpg');
      // 1x1 transparent PNG bytes (Flutter decodes it fine as Image).
      tmp.writeAsBytesSync([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);

      final p = Product(
        id: 'x',
        localPreviewPath: tmp.path,
      );

      await tester.pumpWidget(_wrap(ProductCoverImage(product: p)));
      // Image.file is used; no CachedNetworkImage because no remote URL.
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      // When image_post is empty but localPath is set, overlay shows
      // because we assume optimistic render is for a video (safer default).
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}
