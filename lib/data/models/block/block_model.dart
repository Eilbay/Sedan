import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/block/blocked_user.dart';

/// Single block record returned by POST /blocks/ and GET /blocks/.
class BlockModel extends Equatable {
  /// Backend returns a UUID string, not a numeric id.
  final String id;
  final BlockedUser blocked;
  final String? reason;
  final DateTime? createdAt;

  const BlockModel({
    required this.id,
    required this.blocked,
    this.reason,
    this.createdAt,
  });

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    // The backend returns the blocked user inline (user_id / username /
    // image at the top level), not as a nested object. A nested
    // `blocked` / `user` map is still accepted for forward-compatibility.
    final nested = json['blocked'] ?? json['user'];
    final blocked = nested is Map<String, dynamic>
        ? BlockedUser.fromJson(nested)
        : BlockedUser(
            id: (json['user_id'] ?? '').toString(),
            username: (json['username'] ?? '') as String,
            image: json['image'] as String?,
          );
    return BlockModel(
      id: (json['id'] ?? '').toString(),
      blocked: blocked,
      reason: json['reason'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, blocked, reason, createdAt];
}

/// Paginated response for GET /blocks/.
class BlockListModel extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<BlockModel> results;

  const BlockListModel({
    this.count = 0,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory BlockListModel.fromJson(Map<String, dynamic> json) {
    return BlockListModel(
      count: (json['count'] ?? 0) as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List?)
              ?.map((e) => BlockModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
