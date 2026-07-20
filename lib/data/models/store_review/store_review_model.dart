import 'package:optombai/data/models/review/review_model.dart';
import 'package:equatable/equatable.dart';

class StoreReviewModel extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<StoreReviewResult> results;

  const StoreReviewModel({
    this.count = 0,
    this.next,
    this.previous,
    this.results = const [],
  });

  StoreReviewModel copyWith(
      {int? count,
      String? next,
      String? previous,
      List<StoreReviewResult>? results}) {
    return StoreReviewModel(
        count: count ?? this.count,
        next: next ?? this.next,
        previous: previous ?? this.previous,
        results: results ?? this.results);
  }

  factory StoreReviewModel.fromJson(Map<String, dynamic> json) {
    return StoreReviewModel(
      count: json["count"] ?? 0,
      next: json["next"],
      previous: json["previous"],
      results: (json["results"] as List?)
              ?.map((item) => StoreReviewResult.fromJson(item))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}

class StoreReviewResult extends Equatable {
  final int id;
  final ReviewUser? user;
  final String review;
  final int? stars;
  final String shop;
  final int parent_review;
  final List<StoreReviewResult> children;
  final String created_at;

  const StoreReviewResult({
    this.id = 0,
    this.user,
    this.review = '',
    this.shop = '',
    this.stars = 0,
    this.parent_review = 0,
    this.children = const [],
    this.created_at = '',
  });

  StoreReviewResult copyWith({
    int? id,
    ReviewUser? user,
    String? review,
    int? stars,
    String? shop,
    int? parent_review,
    List<StoreReviewResult>? children,
    String? created_at,
  }) {
    return StoreReviewResult(
      id: id ?? this.id,
      user: user ?? this.user,
      review: review ?? this.review,
      shop: shop ?? this.shop,
      stars: stars ?? this.stars,
      parent_review: parent_review ?? this.parent_review,
      children: children ?? this.children,
      created_at: created_at ?? this.created_at,
    );
  }

  factory StoreReviewResult.fromJson(Map<String, dynamic> json) {
    return StoreReviewResult(
      id: json['id'] ?? 0,
      user: json['user'] != null ? ReviewUser.fromJson(json['user']) : null,
      review: json['review'] ?? '',
      stars: json['stars'],
      shop: json['shop'] ?? '',
      parent_review: json['parent_review'] ?? 0,
      children: (json["children"] as List?)
              ?.map((item) => StoreReviewResult.fromJson(item))
              .toList() ??
          const [],
      created_at: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "review": review,
        "stars": stars,
        "shop": shop,
      };

  @override
  List<Object?> get props =>
      [id, user, review, stars, shop, parent_review, children, created_at];
}
