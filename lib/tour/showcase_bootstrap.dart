import 'package:flutter/foundation.dart';
import 'package:showcaseview/showcaseview.dart';

class ShowcaseBootstrap {
  static bool _registered = false;

  static void ensureRegistered() {
    if (_registered) return;
    _registered = true;

    ShowcaseView.register(
      onStart: (key, index) =>
          debugPrint('[SHOWCASE] start index=$index key=$key'),
      onComplete: (key, index) =>
          debugPrint('[SHOWCASE] complete index=$index key=$key'),
      onFinish: () => debugPrint('[SHOWCASE] finish'),
    );
  }
}
