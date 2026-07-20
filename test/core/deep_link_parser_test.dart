import 'package:flutter_test/flutter_test.dart';
import 'package:optombai/core/deep_link/deep_link_parser.dart';

void main() {
  group('extractReelId (https)', () {
    test('returns id from optombai.com/reel/<uuid>', () {
      final uri = Uri.parse(
          'https://optombai.com/reel/9d4188e4-899d-42d2-8ef0-abe2f0ac0767');
      expect(
        DeepLinkParser.extractReelId(uri),
        '9d4188e4-899d-42d2-8ef0-abe2f0ac0767',
      );
    });

    test('accepts www.optombai.com', () {
      final uri = Uri.parse('https://www.optombai.com/reel/abc');
      expect(DeepLinkParser.extractReelId(uri), 'abc');
    });

    test('accepts optombai.vercel.app', () {
      final uri = Uri.parse('https://optombai.vercel.app/reel/abc');
      expect(DeepLinkParser.extractReelId(uri), 'abc');
    });

    test('supports slug-style path (e.g. "меч")', () {
      final uri = Uri.parse('https://optombai.com/reel/меч');
      // Note: Dart's Uri.pathSegments decodes percent-encoding automatically,
      // so Cyrillic slugs arrive as-is.
      expect(DeepLinkParser.extractReelId(uri), 'меч');
    });

    test('ignores foreign hosts', () {
      final uri = Uri.parse('https://evil.com/reel/abc');
      expect(DeepLinkParser.extractReelId(uri), isNull);
    });

    test('ignores non-/reel paths', () {
      expect(
        DeepLinkParser.extractReelId(
          Uri.parse('https://optombai.com/product/abc'),
        ),
        isNull,
      );
      expect(
        DeepLinkParser.extractReelId(Uri.parse('https://optombai.com/reel')),
        isNull,
      );
      expect(
        DeepLinkParser.extractReelId(Uri.parse('https://optombai.com/')),
        isNull,
      );
    });
  });

  group('extractReelId (custom scheme)', () {
    test('optombai://reel/<id> is accepted', () {
      expect(
        DeepLinkParser.extractReelId(Uri.parse('optombai://reel/xyz')),
        'xyz',
      );
    });

    test('optombai://register is rejected', () {
      expect(
        DeepLinkParser.extractReelId(Uri.parse('optombai://register')),
        isNull,
      );
    });
  });

  group('extractProductId', () {
    test('accepts /p/<slug> on supported hosts', () {
      for (final host in [
        'optombai.com',
        'www.optombai.com',
        'optombai.vercel.app',
      ]) {
        final uri = Uri.parse('https://$host/p/test-5kpm');
        expect(DeepLinkParser.extractProductId(uri), 'test-5kpm',
            reason: 'failed on host $host');
      }
    });

    test('accepts optombai://product/<id>', () {
      expect(
        DeepLinkParser.extractProductId(Uri.parse('optombai://product/abc')),
        'abc',
      );
    });

    test('rejects /reel/', () {
      expect(
        DeepLinkParser.extractProductId(
          Uri.parse('https://optombai.com/reel/abc'),
        ),
        isNull,
      );
    });
  });

  group('isReferralRegisterLink', () {
    test('accepts /register path', () {
      expect(
        DeepLinkParser.isReferralRegisterLink(
          Uri.parse('https://optombai.com/register?ref=FOO'),
        ),
        isTrue,
      );
    });

    test('accepts /r/<code> shortcut', () {
      expect(
        DeepLinkParser.isReferralRegisterLink(
          Uri.parse('https://optombai.com/r/FOO'),
        ),
        isTrue,
      );
    });

    test('accepts vercel domain only when it has a referral code', () {
      expect(
        DeepLinkParser.isReferralRegisterLink(
          Uri.parse('https://optombai.vercel.app/?ref=FOO'),
        ),
        isTrue,
      );
      expect(
        DeepLinkParser.isReferralRegisterLink(
          Uri.parse('https://optombai.vercel.app/'),
        ),
        isFalse,
      );
    });

    test('accepts any optombai:// scheme for register', () {
      expect(
        DeepLinkParser.isReferralRegisterLink(
          Uri.parse('optombai://register'),
        ),
        isTrue,
      );
    });
  });

  group('extractReferralCode', () {
    test('reads deep_link_value first', () {
      final uri = Uri.parse(
          'https://optombai.com/?deep_link_value=CODE1&ref=CODE2');
      expect(DeepLinkParser.extractReferralCode(uri), 'CODE1');
    });

    test('falls back to referral_code', () {
      final uri = Uri.parse('https://optombai.com/?referral_code=X');
      expect(DeepLinkParser.extractReferralCode(uri), 'X');
    });

    test('falls back to ref', () {
      final uri = Uri.parse('https://optombai.com/?ref=Y');
      expect(DeepLinkParser.extractReferralCode(uri), 'Y');
    });

    test('falls back to /r/<code> path', () {
      final uri = Uri.parse('https://optombai.com/r/PATHCODE');
      expect(DeepLinkParser.extractReferralCode(uri), 'PATHCODE');
    });

    test('returns null when no code anywhere', () {
      expect(
        DeepLinkParser.extractReferralCode(
          Uri.parse('https://optombai.com/some/path'),
        ),
        isNull,
      );
    });

    test('trims whitespace', () {
      final uri = Uri.parse('https://optombai.com/?ref=%20%20CODE%20');
      expect(DeepLinkParser.extractReferralCode(uri), 'CODE');
    });
  });
}
