import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches reel list metadata in SharedPreferences so reels are available
/// instantly on app restart (before the API call completes).
abstract class IReelMetadataCache {
  /// Load cached reel list. Returns null if nothing is cached.
  ReelListModel? loadCached();

  /// Save reel list to cache.
  Future<void> save(ReelListModel reelList);

  /// Clear the cached data.
  Future<void> clear();
}

class ReelMetadataCache implements IReelMetadataCache {
  /// Versioned cache key. Bump suffix on schema changes so old snapshots
  /// (without new fields like HLS metadata) are discarded automatically.
  static const _key = 'cached_reel_metadata_v3';
  static const _legacyKey = 'cached_reel_metadata';
  static const _legacyKeyV2 = 'cached_reel_metadata_v2';

  final SharedPreferences _prefs;

  ReelMetadataCache({required SharedPreferences prefs}) : _prefs = prefs {
    if (_prefs.containsKey(_legacyKey)) {
      _prefs.remove(_legacyKey);
    }
    if (_prefs.containsKey(_legacyKeyV2)) {
      _prefs.remove(_legacyKeyV2);
    }
  }

  @override
  ReelListModel? loadCached() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ReelListModel.fromJson(json);
    } catch (e) {
      debugPrint('[REEL-CACHE] failed to parse cached metadata: $e');
      return null;
    }
  }

  @override
  Future<void> save(ReelListModel reelList) async {
    try {
      final json = jsonEncode(reelList.toJson());
      await _prefs.setString(_key, json);
      debugPrint('[REEL-CACHE] saved ${reelList.results.length} reels to cache');
    } catch (e) {
      debugPrint('[REEL-CACHE] failed to save: $e');
    }
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
