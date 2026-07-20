/// Pure parsing of incoming deep-link URIs.
///
/// Kept separate from the widget layer so we can unit-test link handling
/// without spinning up the entire App widget tree.
///
/// Supported shapes:
///   optombai://product/<id>
///   optombai://reel/<id>
///   optombai://register
///   kitaydan://p/<id>
///   kitaydan://reel/<id>
///   kitaydan://r/<referral_code>
///   kitaydan://register
///   https://optombai.com/p/<slug>
///   https://optombai.com/reel/<id>
///   https://optombai.com/register
///   https://optombai.com/r/<referral_code>
///   + same with www.optombai.com and optombai.vercel.app
class DeepLinkParser {
  static const _supportedHosts = {
    'optombai.com',
    'www.optombai.com',
    'optombai.vercel.app',
  };

  /// Custom-scheme deep links emitted by the web landing page redirect.
  static const _customSchemes = {'optombai', 'kitaydan'};

  static bool isSupportedWebLink(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    return _supportedHosts.contains(uri.host);
  }

  static String? extractProductId(Uri uri) {
    // optombai://product/<id>
    if (uri.scheme == 'optombai' && uri.host == 'product') {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.last;
    }
    // kitaydan://p/<id> — landing-page redirect format
    if (uri.scheme == 'kitaydan' && uri.host == 'p') {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.last;
    }
    if (!isSupportedWebLink(uri)) return null;
    if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'p') {
      return uri.pathSegments[1];
    }
    return null;
  }

  static String? extractReelId(Uri uri) {
    if (_customSchemes.contains(uri.scheme) && uri.host == 'reel') {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.last;
    }
    if (!isSupportedWebLink(uri)) return null;
    if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'reel') {
      return uri.pathSegments[1];
    }
    return null;
  }

  static bool isReferralRegisterLink(Uri uri) {
    final hasCode = (uri.queryParameters['referral_code']?.trim().isNotEmpty ??
            false) ||
        (uri.queryParameters['ref']?.trim().isNotEmpty ?? false) ||
        (uri.queryParameters['deep_link_value']?.trim().isNotEmpty ?? false);

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      if (uri.host == 'optombai.vercel.app' && hasCode) return true;
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'register') {
        return true;
      }
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'r') {
        return true;
      }
      if (hasCode) return true;
    }

    if (_customSchemes.contains(uri.scheme) && uri.host == 'register') {
      return true;
    }
    if (_customSchemes.contains(uri.scheme) && uri.host == 'r') {
      return true;
    }

    return false;
  }

  /// Extracts a referral code from any of the supported sources, trimmed.
  /// Returns null if nothing found or the result would be empty.
  static String? extractReferralCode(Uri uri) {
    String? code;
    code = uri.queryParameters['deep_link_value']?.trim();
    code ??= uri.queryParameters['referral_code']?.trim();
    code ??= uri.queryParameters['ref']?.trim();

    if (code == null || code.isEmpty) {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'r') {
        code = segments[1].trim();
      }
      // kitaydan://r/<code> — host = 'r', first segment = code
      if (_customSchemes.contains(uri.scheme) && uri.host == 'r') {
        if (segments.isNotEmpty) {
          code = segments.first.trim();
        }
      }
    }

    if (code == null || code.isEmpty) return null;
    return code;
  }
}
