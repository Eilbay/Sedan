import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/core/error/reel_log_file.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';
import 'package:optombai/services/reel_metadata_cache.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'reel_event.dart';
part 'reel_state.dart';

class ReelBloc extends Bloc<ReelEvent, ReelState> {
  final IReelRepository _repository;
  final IReelMetadataCache _metadataCache;
  final SharedPreferences preferences;

  ReelBloc({
    required IReelRepository repository,
    required IReelMetadataCache metadataCache,
    required this.preferences,
  })  : _repository = repository,
        _metadataCache = metadataCache,
        super(const ReelState()) {
    on<FetchReelsEvent>(_onFetchReels);
    on<FilterReelsByCategoryEvent>(_onFilterByCategory);
    on<FetchMoreReelsEvent>(_onFetchMoreReels);
    on<LikeReelEvent>(_onLikeReel);
    on<UnlikeReelEvent>(_onUnlikeReel);
    on<RegisterViewEvent>(_onRegisterView);
    on<SaveLastViewedReelIndexEvent>(_onSaveLastViewedReelIndex);
    on<LoadCachedReelsEvent>(_onLoadCachedReels);
    on<InvalidateReelsCacheEvent>((event, emit) async {
      // Keep the currently-loaded reels on screen while re-fetching in the
      // background. Emitting a fresh `ReelState()` here used to reset
      // `reels` to `[]` immediately — after every product upload/edit,
      // anyone on the Reels tab at that moment saw "Видео пока нет" flash
      // for the ~0.5-1s round trip before the real list reappeared.
      emit(state.copyWith(isLoading: true));
      await _onFetchReels(FetchReelsEvent(forceRefresh: true), emit);
    });
    on<OptimisticRemoveReelEvent>(_onOptimisticRemoveReel);
  }

  void _onOptimisticRemoveReel(
    OptimisticRemoveReelEvent event,
    Emitter<ReelState> emit,
  ) {
    final filtered = state.reels.where((r) => r.id != event.reelId).toList();
    if (filtered.length == state.reels.length) return;
    emit(state.copyWith(reels: filtered));
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  /// Logs a reel-feed diagnostic event to both the general Talker log and
  /// the dedicated `reel_log.txt` — the latter keeps reel events easy to
  /// find instead of buried under the much higher-volume HTTP/lifecycle
  /// noise in the general crash log.
  void _logReelEvent(String message, {bool isWarning = false}) {
    if (isWarning) {
      talker.warning(message);
    } else {
      talker.info(message);
    }
    ReelLogFile.append('[${DateTime.now().toIso8601String()}] $message\n');
  }

  void _onLoadCachedReels(LoadCachedReelsEvent event, Emitter<ReelState> emit) {
    final cached = _metadataCache.loadCached();
    if (cached != null && cached.results.isNotEmpty) {
      _logReelEvent('[REEL-FEED] loaded ${cached.results.length} reels from local cache');
      emit(state.copyWith(
        isSuccess: true,
        reels: cached.results,
        nextPageUrl: cached.next,
        hasReachedEnd: cached.next == null,
      ));
    }
  }

  Future<void> _onFetchReels(FetchReelsEvent event, emit) async {
    if (!event.forceRefresh && state.reels.isNotEmpty) {
      _logReelEvent(
          '[REEL-FEED] skip fetch — already have ${state.reels.length} reels cached');
      return;
    }

    _logReelEvent(
        '[REEL-FEED] fetch start forceRefresh=${event.forceRefresh} currentCount=${state.reels.length} tokenPresent=${getToken().isNotEmpty}');
    final sw = Stopwatch()..start();
    // Background refresh: only show loading spinner if no reels cached yet.
    emit(state.copyWith(
      isLoading: state.reels.isEmpty,
      errors: [],
    ));
    try {
      var reelList = await _repository.fetchReels(
        getToken(),
        categoryId: state.categoryId,
        forceRefresh: event.forceRefresh,
      );

      // A forced refresh that comes back empty is far more likely to be a
      // transient glitch (auth race, backend hiccup) than the feed
      // genuinely running dry — the reels-feed endpoint is cyclic and
      // never legitimately empty once it has served reels before. Keep
      // showing the last known-good list instead of flashing an empty
      // "Видео пока нет" state that self-heals on the next refresh.
      if (event.forceRefresh &&
          reelList.results.isEmpty &&
          state.reels.isNotEmpty) {
        _logReelEvent(
            '[REEL-FEED] forceRefresh returned 0 results while ${state.reels.length} were loaded — keeping existing list, treating as transient (${sw.elapsedMilliseconds}ms)',
            isWarning: true);
        emit(state.copyWith(isLoading: false));
        return;
      }

      _logReelEvent(
          '[REEL-FEED] fetch done ${sw.elapsedMilliseconds}ms — ${reelList.results.length} reels, next=${reelList.next != null}');
      emit(state.copyWith(
        isSuccess: true,
        reels: reelList.results,
        isLoading: false,
        nextPageUrl: reelList.next,
        hasReachedEnd: reelList.next == null,
      ));

      // Persist to local cache for instant load on next app start.
      _metadataCache.save(reelList);
    } on AppException catch (e) {
      _logReelEvent(
          '[REEL-FEED] fetch error ${sw.elapsedMilliseconds}ms — ${e.messages}',
          isWarning: true);
      emit(state.copyWith(
        errors: e.messages,
        isLoading: false,
      ));
    }
  }

  Future<void> _onFilterByCategory(
    FilterReelsByCategoryEvent event,
    Emitter<ReelState> emit,
  ) async {
    // Ignore if the same filter is already applied.
    if (event.categoryId == state.categoryId) return;

    // Reset the list and reload with the new filter. Setting reels=[] is
    // important: otherwise the viewer keeps showing old reels while we
    // wait for the server.
    emit(state.copyWith(
      categoryId: event.categoryId,
      reels: const [],
      isLoading: true,
      isSuccess: false,
      nextPageUrl: null,
      hasReachedEnd: false,
      errors: const [],
    ));

    try {
      final reelList = await _repository.fetchReels(
        getToken(),
        categoryId: event.categoryId,
      );
      emit(state.copyWith(
        isSuccess: true,
        reels: reelList.results,
        isLoading: false,
        nextPageUrl: reelList.next,
        hasReachedEnd: reelList.next == null,
      ));
      // Cache only the unfiltered feed — category-filtered lists are
      // short-lived and shouldn't overwrite the default cache.
      if (event.categoryId == null) {
        _metadataCache.save(reelList);
      }
    } on AppException catch (e) {
      emit(state.copyWith(
        errors: e.messages,
        isLoading: false,
      ));
    }
  }

  Future<void> _onFetchMoreReels(FetchMoreReelsEvent event, emit) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.nextPageUrl == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));
    try {
      final reelList = await _repository.fetchMoreReels(
        state.nextPageUrl!,
        getToken(),
      );

      // The reels-feed is cyclic on the backend — once we page past the unique
      // set it starts repeating reels (verified: offset wraps modulo count).
      // Dedup by id and, when a page brings nothing new, mark the feed complete:
      // from here the viewer loops the loaded set client-side (PageView `_wrap`)
      // instead of accumulating duplicates forever (unbounded memory + useless
      // network).
      final existingIds = state.reels.map((r) => r.id).toSet();
      final fresh =
          reelList.results.where((r) => existingIds.add(r.id)).toList();

      emit(state.copyWith(
        reels: [...state.reels, ...fresh],
        isLoadingMore: false,
        nextPageUrl: reelList.next,
        hasReachedEnd: fresh.isEmpty || reelList.next == null,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errors: e.messages,
      ));
    }
  }

  Future<void> _onLikeReel(LikeReelEvent event, emit) async {
    try {
      emit(state.setLiked(event.reelId, isLiked: true));

      await _repository.likeReel(event.reelId, getToken());
    } on AppException catch (e) {
      emit(state.setLiked(event.reelId, isLiked: false));
      emit(state.copyWith(errors: e.messages));
    }
  }

  Future<void> _onUnlikeReel(UnlikeReelEvent event, emit) async {
    try {
      emit(state.setLiked(event.reelId, isLiked: false));

      await _repository.unlikeReel(event.reelId, getToken());
    } on AppException catch (e) {
      emit(state.setLiked(event.reelId, isLiked: true));
      emit(state.copyWith(errors: e.messages));
    }
  }

  Future<void> _onRegisterView(RegisterViewEvent event, emit) async {
    final token = getToken();
    if (token.isEmpty) return;

    try {
      emit(state.incrementViews(event.reelId));

      await _repository.registerView(event.reelId, token);
    } on AppException catch (e) {
      debugPrint('Failed to register view: ${e.messages}');
    }
  }

  Future<void> _onSaveLastViewedReelIndex(
    SaveLastViewedReelIndexEvent event,
    emit,
  ) async {
    try {
      await preferences.setInt('last_viewed_reel_index', event.index);
      emit(state.copyWith(lastViewedReelIndex: event.index));
    } catch (e) {
      debugPrint('Failed to save last viewed reel index: $e');
    }
  }

  int getLastViewedReelIndex() {
    return preferences.getInt('last_viewed_reel_index') ?? 0;
  }
}
