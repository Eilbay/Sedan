import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:optombai/app/app.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/firebase_options.dart';
import 'package:optombai/services/config_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:optombai/services/iap_service.dart';
import 'package:optombai/core/debug/frame_timing_logger.dart';
import 'package:optombai/core/debug/heartbeat_service.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/error/app_lifecycle_logger.dart';
import 'package:optombai/core/error/crash_log_file.dart';
import 'package:optombai/core/error/global_error_handler.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';
import 'package:optombai/services/memory_pressure_handler.dart';
import 'package:media_kit/media_kit.dart';
// Cart models for Hive
import 'package:optombai/data/models/cart/cart_item_model.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/data/models/cart/order_status_model.dart';
import 'package:optombai/data/models/cart/delivery_type.dart';

void main() async {
  // Catch every async error escaping any try-catch in the app.
  await runZonedGuarded(_appMain, (error, stack) {
    GlobalErrorHandler.handleError(error, stack, source: ErrorSource.zone);
  });
}

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[INIT] _appMain started');
  // Write a session marker so the file always exists for share() even
  // when no errors have happened yet.
  unawaited(CrashLogFile.append(
    '=== ${DateTime.now().toIso8601String()} ===\n'
    'app started (session marker)\n\n',
  ));

  // Framework errors (build, layout, paint).
  FlutterError.onError = (details) {
    GlobalErrorHandler.handleError(
      details.exception,
      details.stack,
      source: ErrorSource.flutter,
    );
  };

  // Async errors that escape the zone (platform-channel, isolates).
  PlatformDispatcher.instance.onError = (error, stack) {
    GlobalErrorHandler.handleError(error, stack, source: ErrorSource.platform);
    return true;
  };

  // TODO(phase-2): remove MediaKit.ensureInitialized once silent_video_preview
  // and video_view_screen migrate off media_kit.
  MediaKit.ensureInitialized();

  // Firebase is required for blocs/services created right after runApp.
  await _initializeFirebase();

  // Initialize SharedPreferences
  final preferences = await SharedPreferences.getInstance();

  // Initialize DI container
  configureDependencies(preferences);

  // Fast config bootstrap from local cache (no network blocking startup).
  ConfigService.initFast(preferences);

  // Keep cart persistence ready before app starts to avoid race conditions.
  await _initializeHive();

  // Hook OS memory-pressure notifications to drop the pre-buffer pool
  // before iOS/Android decide to kill us. Must run AFTER DI is configured.
  MemoryPressureHandler(preBufferService: getIt<IVideoPreBufferService>()).attach();
  debugPrint('[INIT] memory pressure handler attached');

  // Hook AppLifecycleState transitions so we get clean-shutdown markers
  // in the log file. Without these, every native OOM kill looks the
  // same as a clean exit.
  AppLifecycleLogger.attach();
  // Check if the previous session ended without a shutdown marker —
  // that signals an OOM/watchdog kill we can't catch in real time.
  unawaited(AppLifecycleLogger.detectPreviousCrash());

  // UI freeze detector — emits warnings for frames > 500ms (hitch) or
  // > 2s (freeze). When the last log before a crash is a [FRAME] ***
  // UI FREEZE *** entry, the crash was a watchdog kill, not OOM.
  FrameTimingLogger.instance.attach();

  // Periodic "alive" beacon — last heartbeat timestamp shows exact
  // time of death after a native kill. Also logs RSS for leak hunting.
  HeartbeatService.instance.start();

  runApp(ChangeNotifierProvider(
    create: (context) => ThemeNotifier(),
    child: MyApp(
      preferences: preferences,
    ),
  ));

  // Non-critical services are initialized after first frame.
  unawaited(_initializeDeferredServices());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Crashlytics: enable collection in every build. We rely on
    // Crashlytics for both debug-time test crashes (manual ⚡ button)
    // and production crash reporting. To avoid debug spam in the
    // dashboard later, filter by app version in Firebase Console.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

Future<void> _initializeHive() async {
  try {
    await Hive.initFlutter();

    // Register Hive adapters for Cart.
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CartItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(OrderStatusTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(OrderStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(DeliveryTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(OrderAdapter());
    }

    if (!Hive.isBoxOpen('cartItems')) {
      await Hive.openBox<CartItem>('cartItems');
    }
    if (!Hive.isBoxOpen('orders')) {
      await Hive.openBox<Order>('orders');
    }
  } catch (e) {
    debugPrint('Hive initialization error: $e');
  }
}

Future<void> _initializeDeferredServices() async {
  await Future<void>.delayed(const Duration(milliseconds: 100));

  try {
    await ConfigService.refreshConfig();
  } catch (e) {
    debugPrint('ConfigService refresh error: $e');
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('.env load error: $e');
  }

  try {
    await IAPService().initialize();
  } catch (e) {
    debugPrint('IAPService initialization error: $e');
  }
}
