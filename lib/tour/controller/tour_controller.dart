import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:optombai/tour/model/tour_step.dart';
import 'package:optombai/widgets/bottom_nav.dart';

class TourController extends ChangeNotifier {
  bool isRunning = false;

  int stepIndex = 0;
  int innerIndex = 0;

  final List<TourStep> steps;
  BuildContext? _ctx;

  TourController(this.steps);

  bool _startGuard = false;
  bool _postFrameNotifyScheduled = false;

  bool _advanceLocked = false;

  void attachContext(BuildContext context) {
    _ctx = context;
  }

  void next() {
    final ctx = _ctx;
    if (ctx == null) {
      debugPrint('[TOUR] next() skipped: no ctx attached');
      return;
    }
    if (!isRunning) {
      debugPrint('[TOUR] next() ignored: not running');
      return;
    }
    if (_advanceLocked) {
      debugPrint('[TOUR] next() ignored: locked');
      return;
    }

    _advanceLocked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _advanceLocked = false;
    });

    nextStep(ctx);
  }

  void start(BuildContext context) {
    if (steps.isEmpty) return;

    if (_startGuard && isRunning) {
      debugPrint(
        '[TOUR] start ignored (already running) hash=${identityHashCode(this)}',
      );
      return;
    }

    _startGuard = true;
    isRunning = true;
    stepIndex = 0;
    innerIndex = 0;

    attachContext(context);

    debugPrint('[TOUR] start hash=${identityHashCode(this)} step=$stepIndex');
    notifyListeners();
    _goToStep(context);
  }

  void stop() {
    debugPrint('[TOUR] stop hash=${identityHashCode(this)}');
    isRunning = false;
    innerIndex = 0;
    notifyListeners();
  }

  void nextStep(BuildContext context) {
    debugPrint(
      '[TOUR] nextStep BEFORE hash=${identityHashCode(this)} running=$isRunning step=$stepIndex inner=$innerIndex',
    );

    if (!isRunning) return;
    if (steps.isEmpty) return;

    if (stepIndex < 0 || stepIndex >= steps.length) {
      stop();
      return;
    }

    stepIndex++;
    innerIndex = 0;

    debugPrint(
      '[TOUR] nextStep AFTER  hash=${identityHashCode(this)} step=$stepIndex/${steps.length}',
    );

    if (stepIndex >= steps.length) {
      stop();
      return;
    }

    attachContext(context);

    notifyListeners();
    _goToStep(context);
  }

  void _goToStep(BuildContext context) {
    if (!isRunning) return;

    if (stepIndex < 0 || stepIndex >= steps.length) {
      stop();
      return;
    }

    final step = steps[stepIndex];

    if (step.canRun != null && !step.canRun!(context)) {
      debugPrint('[TOUR] step $stepIndex skipped by canRun()');
      nextStep(context);
      return;
    }

    debugPrint(
      '[TOUR] goToStep hash=${identityHashCode(this)} step=$stepIndex tab=${step.tabIndex}',
    );

    attachContext(context);

    if (step.tabIndex != null) {
      BottomNav.of(context)?.setTab(step.tabIndex!);
    }

    final noShowcase = step.showcaseKeys.isEmpty;
    if (noShowcase) {
      if (step.onEnter != null) {
        step.onEnter!(context);
      }
      return;
    }

    _schedulePostFrameNotify();

    if (step.onEnter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isRunning) return;
        step.onEnter!(context);
      });
    }
  }

  void _schedulePostFrameNotify() {
    if (_postFrameNotifyScheduled) return;
    _postFrameNotifyScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameNotifyScheduled = false;
      if (!isRunning) return;

      debugPrint(
        '[TOUR] postFrame notify hash=${identityHashCode(this)} step=$stepIndex',
      );
      notifyListeners();
    });
  }
}
