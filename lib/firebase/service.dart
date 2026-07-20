import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _subscription;

  Stream<bool> listenToButtonVisibility() {
    return _databaseRef.child('isButtonVisible').onValue.map((event) {
      if (event.snapshot.exists) {
        return event.snapshot.value as bool? ?? false;
      }
      return false;
    });
  }

  Future<bool> getButtonVisibility() async {
    try {
      final snapshot = await _databaseRef.child('isButtonVisible').get();
      if (snapshot.exists) {
        return snapshot.value as bool? ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to get button visibility: $e');
    }
  }

  Future<void> setButtonVisibility(bool isVisible) async {
    try {
      await _databaseRef.child('isButtonVisible').set(isVisible);
    } catch (e) {
      throw Exception('Failed to set button visibility: $e');
    }
  }

  /// Generic remote toggles for hiding a feature without an app release.
  /// Each flag lives at `featureFlags/<key>`; a missing key means hidden,
  /// matching the [getButtonVisibility] convention above.
  Stream<Map<String, bool>> listenToFeatureFlags() {
    return _databaseRef.child('featureFlags').onValue.map((event) {
      return _parseFeatureFlags(event.snapshot);
    });
  }

  Future<Map<String, bool>> getFeatureFlags() async {
    try {
      final snapshot = await _databaseRef.child('featureFlags').get();
      return _parseFeatureFlags(snapshot);
    } catch (e) {
      throw Exception('Failed to get feature flags: $e');
    }
  }

  Map<String, bool> _parseFeatureFlags(DataSnapshot snapshot) {
    if (!snapshot.exists) return const {};
    final raw = snapshot.value;
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value == true));
  }

  void dispose() {
    _subscription?.cancel();
  }
}