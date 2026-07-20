import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/debug/talker_instance.dart';

/// Strategy profile derived from the current network type. Drives both
/// pre-buffer concurrency and HLS start-bitrate selection in mpv.
enum NetworkProfile {
  /// Wi-Fi or ethernet — assume fast, stable connection.
  fast,

  /// Mobile data — assume 4G/LTE class throughput.
  mobile,

  /// Anything unknown, 2G/Edge, or no connectivity probe answer.
  slow,
}

/// Provides network-aware configuration values for video playback.
abstract class IConnectivityConfig {
  /// Returns optimal pre-buffer concurrency based on the current network.
  Future<int> optimalPreBufferConcurrency();

  /// Returns the current network profile.
  Future<NetworkProfile> currentProfile();

}

class ConnectivityConfig implements IConnectivityConfig {
  final Connectivity _connectivity;

  ConnectivityConfig({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<NetworkProfile> currentProfile() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final profile = _profileFor(results);
      talker.info('[CONNECTIVITY] results=$results profile=$profile');
      return profile;
    } catch (e) {
      talker.info('[CONNECTIVITY] probe failed: $e — falling back to slow');
      return NetworkProfile.slow;
    }
  }

  @override
  Future<int> optimalPreBufferConcurrency() async {
    final profile = await currentProfile();
    switch (profile) {
      case NetworkProfile.fast:
        return 3;
      case NetworkProfile.mobile:
        return 2;
      case NetworkProfile.slow:
        return 1;
    }
  }

  NetworkProfile _profileFor(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return NetworkProfile.fast;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkProfile.mobile;
    }
    return NetworkProfile.slow;
  }
}
