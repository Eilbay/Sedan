import 'package:optombai/data/models/posts/post_model.dart';
import 'package:equatable/equatable.dart';

class FavoriteModel extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<FavoriteResult> results;

  const FavoriteModel(
      {this.count = 0, this.next, this.previous, this.results = const []});

  FavoriteModel copyWith(
      {int? count,
      String? next,
      String? previous,
      List<FavoriteResult>? results}) {
    return FavoriteModel(
        count: count ?? this.count,
        next: next ?? this.next,
        previous: previous ?? this.previous,
        results: results ?? this.results);
  }

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      count: json["count"] ?? 0,
      next: json["next"],
      previous: json["previous"],
      results: (json["results"] as List?)
              ?.map((item) => FavoriteResult.fromJson(item))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}

class FavoriteResult extends Equatable {
  final int id;
  final Product post;

  const FavoriteResult({this.id = 0, required this.post});

  FavoriteResult copyWith({int? id, Product? post}) {
    return FavoriteResult(id: id ?? this.id, post: post ?? this.post);
  }

  factory FavoriteResult.fromJson(Map<String, dynamic> json) {
    return FavoriteResult(
      id: json["id"] ?? 0,
      post: Product.fromJson(json["post"]),
    );
  }

  Future<Map<String, dynamic>> toJson() async => {
        "id": id,
        "post": post.id,
      };

  @override
  List<Object?> get props => [id, post];
}
