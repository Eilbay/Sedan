import 'package:optombai/core/update/update_type.dart';

class AppUpdateInfo {
  const AppUpdateInfo({required this.type, this.storeUrl});

  final UpdateType type;
  final String? storeUrl;

  static const none = AppUpdateInfo(type: UpdateType.none);
}
