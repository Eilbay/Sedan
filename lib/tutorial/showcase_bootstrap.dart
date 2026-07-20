import 'package:showcaseview/showcaseview.dart';

class ShowcaseBootstrap {
  static bool _registered = false;

  static void ensureRegistered() {
    if (_registered) return;
    _registered = true;

    ShowcaseView.register(
      blurValue: 1,
      autoPlayDelay: const Duration(seconds: 3),
      onDismiss: (key) {},
    );
  }

  static void unregister() {
    if (!_registered) return;
    ShowcaseView.get().unregister();
    _registered = false;
  }
}
