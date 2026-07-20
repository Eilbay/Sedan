import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/debug/debug_overlay_controller.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/crash_log_file.dart';

/// Draggable floating shortcut to the API log screen. Sits on top
/// of every screen via the [MaterialApp.builder] overlay. Activated
/// by 10 taps on the bottom nav (see [DebugOverlayController]).
///
/// Gestures:
///   - tap         → open Talker log screen (in-memory ring buffer)
///   - double-tap  → share `crash_log.txt` via system share sheet
///                   (this is the hidden tester escape hatch — they
///                   send you the file over WhatsApp/Telegram)
///   - long-press  → hide the bubble until next activation
class DebugFloatingBubble extends StatefulWidget {
  const DebugFloatingBubble({super.key, required this.router});

  final AppRouter router;

  @override
  State<DebugFloatingBubble> createState() => _DebugFloatingBubbleState();
}

class _DebugFloatingBubbleState extends State<DebugFloatingBubble> {
  Offset? _position;

  static const double _size = 52;
  static const double _crashBtnSize = 36;

  void _triggerTestCrash() {
    HapticFeedback.heavyImpact();
    talker.warning(
      '[TEST-CRASH] manually triggered from debug bubble — '
      'sending to Crashlytics + forcing native crash',
    );
    // Non-fatal report (in case the native crash below fails to upload).
    try {
      FirebaseCrashlytics.instance.recordError(
        Exception('Manual test crash from debug bubble'),
        StackTrace.current,
        reason: 'TEST_CRASH (manual)',
        fatal: true,
      );
    } catch (_) {}
    // Native crash — Crashlytics native handler picks this up on next launch.
    FirebaseCrashlytics.instance.crash();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DebugOverlayController.instance,
      builder: (context, _) {
        if (!DebugOverlayController.instance.visible) {
          return const SizedBox.shrink();
        }
        final media = MediaQuery.of(context);
        final size = media.size;
        final padding = media.padding;

        _position ??= Offset(
          size.width - _size - 16,
          size.height - _size - padding.bottom - 100,
        );

        return Positioned(
          left: _position!.dx,
          top: _position!.dy,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Smaller red button above the main bubble — tap to force
              // a Crashlytics crash so the dashboard activates. Dev only
              // (only visible when the 10-tap debug unlock is active).
              GestureDetector(
                onTap: _triggerTestCrash,
                child: Container(
                  width: _crashBtnSize,
                  height: _crashBtnSize,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final next = _position! + details.delta;
                    _position = Offset(
                      next.dx.clamp(0.0, size.width - _size),
                      next.dy.clamp(
                        padding.top,
                        size.height - _size - padding.bottom,
                      ),
                    );
                  });
                },
                onTap: () => widget.router.push(const TalkerLogRoute()),
                onDoubleTap: () {
                  // Haptic feedback so the user feels the gesture
                  // registered even before the OS share sheet opens.
                  HapticFeedback.mediumImpact();
                  CrashLogFile.share();
                },
                onLongPress: () => DebugOverlayController.instance.hide(),
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
