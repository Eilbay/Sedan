import 'dart:async';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isButtonVisible = false;
  final Map<String, bool> _featureFlags = const {};

  Stream<bool> listenToButtonVisibility() {
    return Stream<bool>.value(_isButtonVisible);
  }

  Future<bool> getButtonVisibility() async => _isButtonVisible;

  Future<void> setButtonVisibility(bool isVisible) async {
    _isButtonVisible = isVisible;
  }

  Stream<Map<String, bool>> listenToFeatureFlags() {
    return Stream<Map<String, bool>>.value(_featureFlags);
  }

  Future<Map<String, bool>> getFeatureFlags() async => _featureFlags;

  void dispose() {}
}
