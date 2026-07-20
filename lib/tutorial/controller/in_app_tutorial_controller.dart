import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/tutorial_step.dart';
import '../ui/in_app_tutorial_overlay.dart';

class InAppTutorialController {
  OverlayEntry? _entry;
  int _index = 0;
  late List<TutorialStep> _steps;

  static const String _prefsKey = 'tutorial_seen_v1';

  Future<void> startIfNeeded(
      BuildContext context, List<TutorialStep> steps) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_prefsKey) ?? false;
    if (seen) return;

    _steps = steps;
    _index = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) => _show(context));
  }

  void _show(BuildContext context) {
    _entry?.remove();
    _entry = null;

    final step = _steps[_index];
    final rect = _getRect(step.targetKey, step.padding);
    if (rect == null) return;

    _entry = OverlayEntry(
      builder: (_) => InAppTutorialOverlay(
        holeRect: rect,
        step: step,
        index: _index,
        total: _steps.length,
        onNext: () async {
          if (_index < _steps.length - 1) {
            _index++;
            _show(context);
          } else {
            await finish();
          }
        },
        onBack: () {
          if (_index > 0) {
            _index--;
            _show(context);
          }
        },
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  Rect? _getRect(GlobalKey key, EdgeInsets padding) {
    final ctx = key.currentContext;
    if (ctx == null) return null;

    final ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;

    final topLeft = ro.localToGlobal(Offset.zero);
    final r = topLeft & ro.size;

    return Rect.fromLTRB(
      r.left - padding.left,
      r.top - padding.top,
      r.right + padding.right,
      r.bottom + padding.bottom,
    );
  }

  Future<void> finish() async {
    _entry?.remove();
    _entry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  void dispose() {
    _entry?.remove();
    _entry = null;
  }
}
