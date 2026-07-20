import 'package:bloc/bloc.dart';
import 'package:optombai/bloc/comment_bloc/comment_state.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/data/models/comment/comment.dart';
import 'package:optombai/data/models/comment/comment_owner.dart';
import 'package:optombai/data/repositories/i_comment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentCubit extends Cubit<CommentState> {
  final ICommentRepository _repository;
  final SharedPreferences preferences;

  CommentCubit(
      {required ICommentRepository repository, required this.preferences})
      : _repository = repository,
        super(const CommentState());

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";
  Future<void> loadComments(String postId) async {
    emit(state.copyWith(
      isLoading: true,
      currentPostId: postId,
      currentOffset: 0,
      comments: [],
      hasMore: true,
    ));

    try {
      final response = await _repository.getComments(
        postId,
        getToken(),
        limit: state.limit,
        offset: 0,
      );

      emit(state.copyWith(
        comments: response.results,
        isLoading: false,
        error: null,
        totalCount: response.count < response.results.length
            ? response.results.length
            : response.count,
        currentOffset: state.limit,
        hasMore: response.next != null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMoreComments() async {
    if (state.isLoadingMore || !state.hasMore || state.currentPostId == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final response = await _repository.getComments(
        state.currentPostId!,
        getToken(),
        limit: state.limit,
        offset: state.currentOffset,
      );

      final updatedComments = [...state.comments, ...response.results];

      emit(state.copyWith(
        comments: updatedComments,
        isLoadingMore: false,
        error: null,
        totalCount: response.count < updatedComments.length
            ? updatedComments.length
            : response.count,
        currentOffset: state.currentOffset + state.limit,
        hasMore: response.next != null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> createComment(
    String postId,
    String content, {
    required CommentOwner owner,
  }) async {
    if (content.trim().isEmpty) return;

    // Render immediately instead of waiting for the network round-trip.
    final optimisticId = -DateTime.now().microsecondsSinceEpoch;
    final optimisticComment = Comment(
      id: optimisticId,
      postId: postId,
      owner: owner,
      content: content.trim(),
      createdAt: 'Только что',
    );

    emit(state.copyWith(
      comments: [optimisticComment, ...state.comments],
      totalCount: state.totalCount + 1,
      isSubmitting: true,
    ));

    try {
      final newComment = await _repository.createComment(
        postId,
        content,
        getToken(),
      );

      final updatedComments = state.comments
          .map((comment) => comment.id == optimisticId ? newComment : comment)
          .toList(growable: false);

      emit(state.copyWith(
        comments: updatedComments,
        isSubmitting: false,
        error: null,
      ));
    } catch (e) {
      final updatedComments = state.comments
          .where((comment) => comment.id != optimisticId)
          .toList(growable: false);
      emit(state.copyWith(
        comments: updatedComments,
        totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
        isSubmitting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _repository.deleteComment(
          commentId, state.currentPostId ?? "", getToken());

      final updatedComments =
          state.comments.where((comment) => comment.id != commentId).toList();

      emit(state.copyWith(
        comments: updatedComments,
        totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void clearComments() {
    emit(const CommentState());
  }

  void clearError() {
    emit(state.clearError());
  }
}
