import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/posts/posts_stats_by_owner.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRepository extends Mock implements IProductRepository {}

void main() {
  late MockRepository repo;
  late SharedPreferences prefs;
  late ProductBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'TOKEN_KEY': 'test-token'});
    prefs = await SharedPreferences.getInstance();
    repo = MockRepository();
    bloc = ProductBloc(repository: repo, preferences: prefs);
  });

  tearDown(() => bloc.close());

  PostModel _postModel(List<Product> products) => PostModel(
        count: products.length,
        results: products,
      );

  group('OptimisticAddProductEvent', () {
    test('inserts product at the top of products list', () async {
      when(() => repo.fetchProductsByFilter(
            category: any(named: 'category'),
            owner: any(named: 'owner'),
            ordering: any(named: 'ordering'),
            price: any(named: 'price'),
            priceGte: any(named: 'priceGte'),
            priceLte: any(named: 'priceLte'),
            search: any(named: 'search'),
            typeProduct: any(named: 'typeProduct'),
            typeOwner: any(named: 'typeOwner'),
            countryId: any(named: 'countryId'),
            currency: any(named: 'currency'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer(
        (_) async => _postModel([Product(id: 'old')]),
      );

      bloc.add(ProductWithFilter());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(OptimisticAddProductEvent(Product(id: 'new')));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.products.map((p) => p.id), ['new', 'old']);
      expect(bloc.state.totalQuantity, 2);
    });

    test('OptimisticRemoveProductEvent rolls back a previously inserted card',
        () async {
      when(() => repo.fetchProductsByFilter(
            category: any(named: 'category'),
            owner: any(named: 'owner'),
            ordering: any(named: 'ordering'),
            price: any(named: 'price'),
            priceGte: any(named: 'priceGte'),
            priceLte: any(named: 'priceLte'),
            search: any(named: 'search'),
            typeProduct: any(named: 'typeProduct'),
            typeOwner: any(named: 'typeOwner'),
            countryId: any(named: 'countryId'),
            currency: any(named: 'currency'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer(
        (_) async => _postModel([Product(id: 'existing')]),
      );

      bloc.add(ProductWithFilter());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(OptimisticAddProductEvent(Product(id: 'opt')));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.products.map((p) => p.id), ['opt', 'existing']);
      expect(bloc.state.totalQuantity, 2);

      bloc.add(OptimisticRemoveProductEvent('opt'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.products.map((p) => p.id), ['existing']);
      expect(bloc.state.totalQuantity, 1);
    });

    test('OptimisticRemoveProductEvent is a no-op when id is absent', () async {
      when(() => repo.fetchProductsByFilter(
            category: any(named: 'category'),
            owner: any(named: 'owner'),
            ordering: any(named: 'ordering'),
            price: any(named: 'price'),
            priceGte: any(named: 'priceGte'),
            priceLte: any(named: 'priceLte'),
            search: any(named: 'search'),
            typeProduct: any(named: 'typeProduct'),
            typeOwner: any(named: 'typeOwner'),
            countryId: any(named: 'countryId'),
            currency: any(named: 'currency'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer(
        (_) async => _postModel([Product(id: 'real')]),
      );

      bloc.add(ProductWithFilter());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(OptimisticRemoveProductEvent('ghost'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.products.map((p) => p.id), ['real']);
      expect(bloc.state.totalQuantity, 1);
    });

    test('does not duplicate when product with same id already exists',
        () async {
      when(() => repo.fetchProductsByFilter(
            category: any(named: 'category'),
            owner: any(named: 'owner'),
            ordering: any(named: 'ordering'),
            price: any(named: 'price'),
            priceGte: any(named: 'priceGte'),
            priceLte: any(named: 'priceLte'),
            search: any(named: 'search'),
            typeProduct: any(named: 'typeProduct'),
            typeOwner: any(named: 'typeOwner'),
            countryId: any(named: 'countryId'),
            currency: any(named: 'currency'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer(
        (_) async => _postModel([Product(id: 'dup')]),
      );

      bloc.add(ProductWithFilter());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(OptimisticAddProductEvent(Product(id: 'dup')));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.products.length, 1);
    });
  });

  group('RefreshCurrentFilterEvent', () {
    test('replays last ProductWithFilter preserving its filter values',
        () async {
      var call = 0;
      when(() => repo.fetchProductsByFilter(
            category: any(named: 'category'),
            owner: any(named: 'owner'),
            ordering: any(named: 'ordering'),
            price: any(named: 'price'),
            priceGte: any(named: 'priceGte'),
            priceLte: any(named: 'priceLte'),
            search: any(named: 'search'),
            typeProduct: any(named: 'typeProduct'),
            typeOwner: any(named: 'typeOwner'),
            countryId: any(named: 'countryId'),
            currency: any(named: 'currency'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          )).thenAnswer((_) async {
        call++;
        return _postModel([Product(id: 'p$call')]);
      });

      bloc.add(ProductWithFilter(
        category: 'cat-1',
        typeProduct: 2,
        countryId: 18,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(bloc.state.products.single.id, 'p1');

      // RefreshCurrentFilterEvent must force a new call with the same filter.
      bloc.add(RefreshCurrentFilterEvent());
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(call, greaterThanOrEqualTo(2),
          reason: 'Refresh must bypass cache (forceRefresh=true)');
      // The preserved filter values must reach the repository.
      verify(() => repo.fetchProductsByFilter(
            category: 'cat-1',
            typeProduct: 2,
            countryId: 18,
            owner: null,
            ordering: null,
            price: null,
            priceGte: null,
            priceLte: null,
            search: null,
            typeOwner: null,
            currency: null,
            limit: 20,
            offset: 0,
          )).called(greaterThanOrEqualTo(2));
    });

    test('falls back to FetchAllProductsEvent when no filter was applied',
        () async {
      when(() => repo.fetchProductsByFilter()).thenAnswer(
        (_) async => _postModel([Product(id: 'x')]),
      );

      bloc.add(RefreshCurrentFilterEvent());
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // FetchAllProductsEvent runs fetchProductsByFilter() with no args.
      verify(() => repo.fetchProductsByFilter()).called(1);
    });
  });
}
