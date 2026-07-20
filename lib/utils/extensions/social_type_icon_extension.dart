import 'package:optombai/data/models/account/user/socials/social_type.dart';

/// Maps a social network's [SocialType.title] to a local, unified icon
/// asset instead of the backend-provided [SocialType.logo] URL, whose
/// images vary in style/quality per network. Unknown titles return null so
/// the caller can fall back to the backend logo.
extension SocialTypeIconExtension on SocialType {
  String? get localIconAsset {
    switch (title.trim().toLowerCase()) {
      case 'instagram':
        return 'assets/icons/socials/instagram1.png';
      case 'telegram':
        return 'assets/icons/socials/telegram1.png';
      case 'whatsapp':
        return 'assets/icons/socials/whatsapp1.png';
      default:
        return null;
    }
  }
}
