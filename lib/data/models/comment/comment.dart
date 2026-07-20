import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/comment/comment_owner.dart';

class Comment extends Equatable {
  final int id;
  final String postId;
  final CommentOwner owner;
  final String content;
  final String createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.owner,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Comment(
      id: parseInt(json['id']),
      postId: json['post_id']?.toString() ?? '',
      owner: CommentOwner.fromJson(json['owner'] ?? {}),
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'owner': owner.toJson(),
        'content': content,
        'created_at': createdAt,
      };

  Comment copyWith({
    int? id,
    String? postId,
    CommentOwner? owner,
    String? content,
    String? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      owner: owner ?? this.owner,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, postId, owner, content, createdAt];
}

class CommentsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Comment> results;

  const CommentsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory CommentsResponse.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>?)
            ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CommentsResponse(
      count: json['count'] as int? ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: results,
    );
  }
}
