import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/comment_bloc/comment_cubit.dart';
import 'package:optombai/bloc/comment_bloc/comment_state.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/comment/comment_owner.dart';
import 'package:optombai/widgets/comment/comment_card.dart';
import 'package:optombai/widgets/shimmer/shimmer_list_tile.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final ValueChanged<int>? onCommentCountChanged;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    this.onCommentCountChanged,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CommentCubit>().loadComments(widget.postId);

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CommentCubit>().loadMoreComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final dividerColor =
        isDarkMode ? const Color(0xFF2a2a2a) : Colors.grey[300];
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _BottomSheetHandle(isDarkMode: isDarkMode),
          _CommentsHeader(isDarkMode: isDarkMode, textColor: textColor),
          Divider(height: 1, color: dividerColor),
          Expanded(
            child: BlocConsumer<CommentCubit, CommentState>(
              listener: (context, state) {
                final visibleCount = state.totalCount < state.comments.length
                    ? state.comments.length
                    : state.totalCount;
                widget.onCommentCountChanged?.call(visibleCount);

                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  context.read<CommentCubit>().clearError();
                }

                if (!state.isSubmitting) {
                  _scrollToNewestComment();
                }
              },
              builder: (context, state) {
                if (state.isLoading && state.comments.isEmpty) {
                  return Column(
                    children: List.generate(
                      4,
                      (_) => const ShimmerListTile(),
                    ),
                  );
                }

                if (state.comments.isEmpty) {
                  return _CommentsEmptyState(
                      isDarkMode: isDarkMode, textColor: textColor);
                }

                return ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount:
                      state.comments.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.comments.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDarkMode ? Colors.white : Colors.grey[600]!,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final comment = state.comments[index];
                    return CommentCard(
                      comment: comment,
                      isDarkMode: isDarkMode,
                      onDelete: comment.id > 0
                          ? () => _showDeleteDialog(comment.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1, color: dividerColor),
          AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: _CommentInputField(
              isDarkMode: isDarkMode,
              textColor: textColor,
              textController: _textController,
              onSubmit: _submitComment,
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    final cubit = context.read<CommentCubit>();
    final user = context.read<UserBloc>().state.user;
    cubit.createComment(
      widget.postId,
      content,
      owner: CommentOwner(
        id: user.id,
        username: user.username,
        image: user.image?.toString(),
        isPremium: user.isPremium ?? user.userStatus?.isPremium ?? false,
        isVerified: user.is_verified ?? false,
        squareFlag: user.country?.square_flag,
      ),
    );

    _textController.clear();
    _scrollToNewestComment();
    setState(() {});
  }

  void _showDeleteDialog(int commentId) {
    final isDarkMode = context.read<ThemeNotifier>().isDarkMode;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        title: Text(
          'Удалить комментарий?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Это действие нельзя отменить.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<CommentCubit>().deleteComment(commentId);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _scrollToNewestComment() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _BottomSheetHandle extends StatelessWidget {
  final bool isDarkMode;

  const _BottomSheetHandle({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CommentsHeader extends StatelessWidget {
  final bool isDarkMode;
  final Color textColor;

  const _CommentsHeader({
    required this.isDarkMode,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Комментарии',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _CommentsEmptyState extends StatelessWidget {
  final bool isDarkMode;
  final Color textColor;

  const _CommentsEmptyState({
    required this.isDarkMode,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет комментариев',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Будьте первым!',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputField extends StatelessWidget {
  final bool isDarkMode;
  final Color textColor;
  final TextEditingController textController;
  final VoidCallback onSubmit;

  const _CommentInputField({
    required this.isDarkMode,
    required this.textColor,
    required this.textController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentCubit, CommentState>(
      buildWhen: (previous, current) =>
          previous.isSubmitting != current.isSubmitting,
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF262626)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: textController,
                      enabled: !isSubmitting,
                      maxLines: null,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Добавить комментарий...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textController,
                  builder: (context, value, _) {
                    final isEmpty = value.text.trim().isEmpty;
                    return IconButton(
                      icon: Icon(
                        Icons.send,
                        color: isEmpty || isSubmitting
                            ? (isDarkMode ? Colors.grey[700] : Colors.grey)
                            : const Color(0xff0095D5),
                      ),
                      onPressed: isEmpty || isSubmitting ? null : onSubmit,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
