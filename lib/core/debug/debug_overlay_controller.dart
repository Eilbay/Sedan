import 'package:flutter/foundation.dart';

/// Toggles visibility of the floating debug bubble that opens the
/// Talker log screen. Activation gesture: 10 taps on the bottom nav
/// within [_tapWindow]. State is in-memory only — no persistence —
/// so a cold start hides it again.
class DebugOverlayController extends ChangeNotifier {
  DebugOverlayController._();
  static final DebugOverlayController instance = DebugOverlayController._();

  static const _tapWindow = Duration(seconds: 5);
  static const _tapsToActivate = 10;

  bool _visible = false;
  bool get visible => _visible;

  int _tapCount = 0;
  DateTime? _firstTapAt;

  /// Call on every bottom-nav tap. Once [_tapsToActivate] taps arrive
  /// within [_tapWindow], the bubble is toggled.
  void registerTap() {
    final now = DateTime.now();
    if (_firstTapAt == null || now.difference(_firstTapAt!) > _tapWindow) {
      _firstTapAt = now;
      _tapCount = 1;
      return;
    }
    _tapCount++;
    if (_tapCount >= _tapsToActivate) {
      _tapCount = 0;
      _firstTapAt = null;
      _visible = !_visible;
      notifyListeners();
    }
  }

  void hide() {
    if (!_visible) return;
    _visible = false;
    notifyListeners();
  }
}
