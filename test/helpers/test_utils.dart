/// Flushes microtasks repeatedly so async fire-and-forget operations
/// have time to complete.
///
/// Uses [Future.value] instead of [Future.delayed] to avoid Timer-based
/// scheduling that can be intercepted by TestWidgetsFlutterBinding.
Future<void> flushAsync({int times = 30}) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.value();
  }
}
