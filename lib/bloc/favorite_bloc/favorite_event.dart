part of 'favorite_bloc.dart';

@immutable
abstract class FavoriteEvent extends Equatable {}

class FavoriteWithFilter extends FavoriteEvent {
  final String? category;
  final String? owner;
  final String? priceGte;
  final String? priceLte;
  final String? search;
  final String? ordering;
  final int? country;
  final int? productType;
  final String? created;

  FavoriteWithFilter({
    this.country,
    this.productType,
    this.created,
    this.owner,
    this.category,
    this.ordering,
    this.search,
    this.priceLte,
    this.priceGte,
  });

  @override
  List<Object?> get props => [
        category,
        owner,
        ordering,
        search,
        priceGte,
        priceLte,
        created,
        country,
        productType
      ];
}

class FavoriteAllEvent extends FavoriteEvent {
  final String? post_owner;
  final String? name;
  final bool forceRefresh;

  FavoriteAllEvent({this.post_owner, this.name, this.forceRefresh = false});

  @override
  List<Object?> get props => [post_owner, name, forceRefresh];
}

class FavoriteCreateEvent extends FavoriteEvent {
  final String post;
  final FavoriteResult favoriteResult;

  FavoriteCreateEvent({required this.post, required this.favoriteResult});

  @override
  List<Object?> get props => [post, favoriteResult];
}

class FavoriteDelete extends FavoriteEvent {
  final int id;

  FavoriteDelete({required this.id});

  @override
  List<Object?> get props => [id];
}
