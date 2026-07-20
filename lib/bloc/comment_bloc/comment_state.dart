import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/comment/comment.dart';

class CommentState extends Equatable {
  final List<Comment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final bool isLoadingMore;
  final String? error;
  final String? currentPostId;
  final int totalCount;
  final int currentOffset;
  final int limit;
  final bool hasMore;

  const CommentState({
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPostId,
    this.totalCount = 0,
    this.currentOffset = 0,
    this.limit = 20,
    this.hasMore = true,
  });

  CommentState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? isSubmitting,
    bool? isLoadingMore,
    String? error,
    String? currentPostId,
    int? totalCount,
    int? currentOffset,
    int? limit,
    bool? hasMore,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPostId: currentPostId ?? this.currentPostId,
      totalCount: totalCount ?? this.totalCount,
      currentOffset: currentOffset ?? this.currentOffset,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  CommentState clearError() {
    return copyWith(error: null);
  }

  @override
  List<Object?> get props => [
    comments,
    isLoading,
    isSubmitting,
    isLoadingMore,
    error,
    currentPostId,
    totalCount,
    currentOffset,
    limit,
    hasMore,
  ];
}
