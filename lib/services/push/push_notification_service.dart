import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:optombai/features/notifications/data/data_sources/device_remote_data_source.dart';
import 'package:optombai/services/push/current_chat_tracker.dart';
import 'package:optombai/services/push/push_payload.dart';

const String _androidChannelId = 'kitaydan_default';
const String _androidChannelName = 'Уведомления Sedan';
const String _androidChannelDescription = 'Сообщения, лайки и комментарии';

/// Owns the FCM lifecycle: requests permission, fetches the device
/// token, syncs it with the backend, listens to foreground / tap /
/// cold-start messages and forwards parsed [PushPayload]s to a single
/// listener (the app shell handles navigation).
class PushNotificationService {
  PushNotificationService({
    required DeviceRemoteDataSource deviceDataSource,
  })  : _deviceDataSource = deviceDataSource,
        _messaging = FirebaseMessaging.instance,
        _localNotifs = FlutterLocalNotificationsPlugin();

  final DeviceRemoteDataSource _deviceDataSource;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifs;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onTapSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  String? _currentToken;
  void Function(PushPayload payload)? _onTap;
  bool _initialized = false;

  /// True once permission + plugins are set up. Token registration with
  /// the backend happens separately via [registerCurrentDevice].
  bool get isInitialized => _initialized;

  String? get currentToken => _currentToken;

  /// Idempotent: safe to call multiple times.
  Future<void> initialize({
    required void Function(PushPayload payload) onTap,
  }) async {
    _onTap = onTap;
    if (_initialized) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isIOS) {
      // Let iOS render the system banner in foreground — that's the most
      // reliable path. We still get `onMessage` to act on the payload
      // (e.g. analytics or suppression hints), but we don't show a second
      // local banner on iOS to avoid duplicates.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await _initLocalNotifications();

    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _onTapSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);

    _initialized = true;
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS requires the plugin to request its own UNUserNotificationCenter
    // permission so foreground banners shown via `_localNotifs.show()` are
    // actually rendered.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    final androidImpl = _localNotifs.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// Fetch FCM token (lazily, with a short retry on cold start) and
  /// POST it to /devices/register/. Call after the user is logged in.
  Future<void> registerCurrentDevice() async {
    final token = await _fetchTokenWithRetry();
    if (token == null || token.isEmpty) {
      debugPrint('[PUSH] FCM token unavailable — skipping register');
      return;
    }
    _currentToken = token;
    assert(() {
      // Debug-only print of the FCM token so devs can send test pushes via
      // Firebase Console → Cloud Messaging → Send test message.
      // Stripped from release builds by the compiler.
      debugPrint('[PUSH] FCM token = $token');
      return true;
    }());
    try {
      await _deviceDataSource.register(
        fcmToken: token,
        platform: _platformLabel(),
      );
      debugPrint('[PUSH] device registered (${_platformLabel()})');
    } catch (e) {
      debugPrint('[PUSH] register failed: $e');
    }
  }

  /// POST /devices/unregister/ for the current token, then delete it
  /// locally so the next login gets a fresh one.
  Future<void> unregisterCurrentDevice() async {
    final token = _currentToken ?? await _safeGetToken();
    if (token == null || token.isEmpty) return;
    debugPrint(
        '[PUSH] unregisterCurrentDevice token=${token.substring(0, 8)}...');
    try {
      await _deviceDataSource.unregister(token);
      debugPrint('[PUSH] device unregistered');
    } catch (e) {
      debugPrint('[PUSH] unregister failed: $e');
    }
    try {
      await _messaging.deleteToken();
    } catch (_) {}
    _currentToken = null;
  }

  Future<String?> _fetchTokenWithRetry() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final t = await _safeGetToken();
      if (t != null && t.isNotEmpty) return t;
      await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }
    return null;
  }

  Future<String?> _safeGetToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[PUSH] getToken error: $e');
      return null;
    }
  }

  void _handleForeground(RemoteMessage message) {
    debugPrint(
        '[PUSH] onMessage (foreground) — title=${message.notification?.title} data=${message.data}');
    final payload = PushPayload.fromMessage(
      data: Map<String, dynamic>.from(message.data),
      title: message.notification?.title,
      body: message.notification?.body,
    );

    // iOS already renders the banner natively (see
    // setForegroundNotificationPresentationOptions). Showing another local
    // banner would duplicate it. Android still benefits from a local
    // banner because the system doesn't show foreground push by default.
    if (Platform.isIOS) {
      if (CurrentChatTracker.instance.isOpen(payload.chatId)) {
        debugPrint(
          '[PUSH] iOS foreground banner shown by system; '
          'chat ${payload.chatId} is open — cannot suppress per-chat in foreground',
        );
      }
      return;
    }

    if (CurrentChatTracker.instance.isOpen(payload.chatId)) {
      debugPrint('[PUSH] suppressed (chat ${payload.chatId} is open)');
      return;
    }

    debugPrint('[PUSH] showing local banner');
    _showLocalNotification(message, payload);
  }

  void _handleTap(RemoteMessage message) {
    debugPrint(
        '[PUSH] onMessageOpenedApp — title=${message.notification?.title} data=${message.data}');
    final payload = PushPayload.fromMessage(
      data: Map<String, dynamic>.from(message.data),
      title: message.notification?.title,
      body: message.notification?.body,
    );
    _onTap?.call(payload);
  }

  void _onLocalTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    final parts = raw.split('|');
    final data = <String, dynamic>{};
    for (final p in parts) {
      final i = p.indexOf('=');
      if (i <= 0) continue;
      data[p.substring(0, i)] = p.substring(i + 1);
    }
    _onTap?.call(PushPayload.fromMessage(data: data));
  }

  void _showLocalNotification(RemoteMessage message, PushPayload payload) {
    final n = message.notification;
    final title = n?.title ?? payload.title ?? 'Уведомление';
    final body = n?.body ?? payload.body ?? '';

    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifs.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      details,
      payload: _encodePayload(payload),
    );
  }

  String _encodePayload(PushPayload p) {
    final parts = <String>['type=${p.type.apiValue}'];
    if (p.postId != null) parts.add('post_id=${p.postId}');
    if (p.commentId != null) parts.add('comment_id=${p.commentId}');
    if (p.chatId != null) parts.add('chat_id=${p.chatId}');
    return parts.join('|');
  }

  void _handleTokenRefresh(String token) {
    _currentToken = token;
    _deviceDataSource
        .register(fcmToken: token, platform: _platformLabel())
        .catchError((e) => debugPrint('[PUSH] token refresh register: $e'));
  }

  String _platformLabel() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onTapSub?.cancel();
    await _onTokenRefreshSub?.cancel();
  }
}
