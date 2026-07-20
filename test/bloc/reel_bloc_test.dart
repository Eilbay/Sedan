import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';
import 'package:optombai/services/reel_metadata_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockReelRepo extends Mock implements IReelRepository {}

class MockMetadataCache extends Mock implements IReelMetadataCache {}

class FakeReelListModel extends Fake implements ReelListModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeReelListModel());
  });

  late MockReelRepo repo;
  late MockMetadataCache cache;
  late SharedPreferences prefs;
  late ReelBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'TOKEN_KEY': 't'});
    prefs = await SharedPreferences.getInstance();
    repo = MockReelRepo();
    cache = MockMetadataCache();
    when(() => cache.loadCached()).thenReturn(null);
    when(() => cache.save(any())).thenAnswer((_) async {});
    bloc = ReelBloc(repository: repo, metadataCache: cache, preferences: prefs);
  });

  tearDown(() => bloc.close());

  ReelListModel _empty() => const ReelListModel(next: null, results: []);

  group('FilterReelsByCategoryEvent', () {
    test('sends ?category=<uuid> to repository, sets categoryId in state',
        () async {
      when(() => repo.fetchReels(any(), categoryId: any(named: 'categoryId')))
          .thenAnswer((_) async => _empty());

      bloc.add(FilterReelsByCategoryEvent('cat-42'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => repo.fetchReels('t', categoryId: 'cat-42')).called(1);
      expect(bloc.state.categoryId, 'cat-42');
    });

    test('clears filter when categoryId is null (back to "Все")', () async {
      when(() => repo.fetchReels(any(), categoryId: any(named: 'categoryId')))
          .thenAnswer((_) async => _empty());

      // Apply a filter first.
      bloc.add(FilterReelsByCategoryEvent('cat-1'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.categoryId, 'cat-1');

      // Reset via null.
      bloc.add(FilterReelsByCategoryEvent(null));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(bloc.state.categoryId, isNull);
      verify(() => repo.fetchReels('t', categoryId: null)).called(1);
    });

    test('ignores duplicate filter event with same categoryId', () async {
      when(() => repo.fetchReels(any(), categoryId: any(named: 'categoryId')))
          .thenAnswer((_) async => _empty());

      bloc.add(FilterReelsByCategoryEvent('cat-X'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      bloc.add(FilterReelsByCategoryEvent('cat-X'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Only one network call even though the event fired twice.
      verify(() => repo.fetchReels(any(), categoryId: 'cat-X')).called(1);
    });

    test('does not persist category-filtered result to metadata cache',
        () async {
      when(() => repo.fetchReels(any(), categoryId: any(named: 'categoryId')))
          .thenAnswer((_) async => _empty());

      bloc.add(FilterReelsByCategoryEvent('cat-X'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verifyNever(() => cache.save(any()));
    });

    test(
        'clearing filter (null) DOES persist to cache (unfiltered canonical list)',
        () async {
      when(() => repo.fetchReels(any(), categoryId: any(named: 'categoryId')))
          .thenAnswer((_) async => _empty());

      bloc.add(FilterReelsByCategoryEvent('cat-X'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      bloc.add(FilterReelsByCategoryEvent(null));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => cache.save(any())).called(1);
    });
  });

  group('FetchReelsEvent respects active filter', () {
    test('passes current categoryId from state to fetchReels', () async {
      when(() => repo.fetchReels(any(), categoryId: any(named: 'categoryId')))
          .thenAnswer((_) async => _empty());

      // Apply filter so state.categoryId is non-null.
      bloc.add(FilterReelsByCategoryEvent('cat-7'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // forceRefresh=true is required since state.reels still empty would
      // otherwise bypass fetch due to the isEmpty check.
      bloc.add(FetchReelsEvent(forceRefresh: true));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => repo.fetchReels('t', categoryId: 'cat-7'))
          .called(greaterThanOrEqualTo(1));
    });
  });

  group('FetchMoreReelsEvent (cyclic feed dedup)', () {
    ReelModel reel(String id) => ReelModel.fromJson({
          'id': id,
          'owner': {'id': 'o', 'username': 'u'},
          'video_url': 'https://x/$id.mp4',
        });

    test('dedups repeated reels and stops the loop when a page is all dups',
        () async {
      // First page: 2 unique reels, cyclic next.
      when(() => repo.fetchReels(any(),
              categoryId: any(named: 'categoryId'),
              forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => ReelListModel(
              next: 'u?offset=2', results: [reel('a'), reel('b')]));
      // Next page repeats the same reels (backend cycled).
      when(() => repo.fetchMoreReels('u?offset=2', any())).thenAnswer(
          (_) async => ReelListModel(
              next: 'u?offset=4', results: [reel('a'), reel('b')]));

      bloc.add(FetchReelsEvent(forceRefresh: true));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.reels.map((r) => r.id), ['a', 'b']);

      bloc.add(FetchMoreReelsEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // No duplicates appended, and the feed is marked complete so the viewer
      // loops the loaded set instead of paging forever.
      expect(bloc.state.reels.map((r) => r.id), ['a', 'b']);
      expect(bloc.state.hasReachedEnd, isTrue);
    });
  });
}
