import 'package:flutter/foundation.dart';
import 'package:optombai/features/notifications/data/data_sources/device_remote_data_source.dart';
import 'package:optombai/services/push/push_payload.dart';

class PushNotificationService {
  PushNotificationService({
    required DeviceRemoteDataSource deviceDataSource,
  });

  bool _initialized = false;

  bool get isInitialized => _initialized;

  String? get currentToken => null;

  Future<void> initialize({
    required void Function(PushPayload payload) onTap,
  }) async {
    _initialized = true;
    debugPrint('[PUSH] mock initialize');
  }

  Future<void> registerCurrentDevice() async {
    debugPrint('[PUSH] mock register skipped');
  }

  Future<void> unregisterCurrentDevice() async {
    debugPrint('[PUSH] mock unregister skipped');
  }

  Future<void> dispose() async {}
}
