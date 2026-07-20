import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:optombai/core/update/app_update_info.dart';
import 'package:optombai/core/update/update_type.dart';
import 'package:optombai/services/config_service.dart';
import 'package:optombai/utils/extensions/version_extension.dart';

/// Compares the installed app version against the remote config fetched by
/// [ConfigService] (`latest_version_ios/android`, `min_version`) to decide
/// whether to show the soft or hard update gate.
///
/// Fails soft everywhere: any missing/unreachable config value simply means
/// no gate is shown, since [ConfigService] itself already tolerates its
/// remote fetch failing (see its own fallback-to-cache logic).
class AppUpdateChecker {
  Future<AppUpdateInfo> check() async {
    final latestVersion = Platform.isIOS
        ? ConfigService.getLatestVersionIos()
        : ConfigService.getLatestVersionAndroid();
    final minVersion = ConfigService.getMinVersion();
    final storeUrl = Platform.isIOS
        ? ConfigService.getStoreUrlIos()
        : ConfigService.getStoreUrlAndroid();

    if (latestVersion == null && minVersion == null) {
      return AppUpdateInfo.none;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (minVersion != null && currentVersion.isOlderVersionThan(minVersion)) {
      return AppUpdateInfo(type: UpdateType.hard, storeUrl: storeUrl);
    }

    if (latestVersion != null &&
        currentVersion.isOlderVersionThan(latestVersion)) {
      return AppUpdateInfo(type: UpdateType.soft, storeUrl: storeUrl);
    }

    return AppUpdateInfo.none;
  }
}
