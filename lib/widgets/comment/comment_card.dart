import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/data/models/comment/comment.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final bool isDarkMode;
  final VoidCallback? onDelete;

  const CommentCard({super.key, 
    required this.comment,
    required this.isDarkMode,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.user.id != current.user.id,
      builder: (context, userState) {
        final currentUserId = userState.user.id;
        final isOwner = currentUserId == comment.owner.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentAvatar(
                imageUrl: comment.owner.image,
                firstLetter: comment.owner.firstLetter,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.owner.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        if (comment.owner.hasFlag) ...[
                          const SizedBox(width: 4),
                          Text(
                            comment.owner.squareFlag!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        if (comment.owner.isPremium) ...[
                          const SizedBox(width: 4),
                          const _CommentPremiumBadge(),
                        ],
                        if (comment.owner.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xff0095D5),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      comment.createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),

              if (isOwner && onDelete != null)
                _CommentMenuButton(
                  isDarkMode: isDarkMode,
                  onDelete: onDelete!,
                ),
            ],
          ),
        );
      },
    );
  }

}

class _CommentAvatar extends StatelessWidget {
  final String? imageUrl;
  final String firstLetter;

  const _CommentAvatar({
    required this.imageUrl,
    required this.firstLetter,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFF333333),
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _CommentPremiumBadge extends StatelessWidget {
  const _CommentPremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Premium',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CommentMenuButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onDelete;

  const _CommentMenuButton({
    required this.isDarkMode,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
      ),
      onSelected: (value) {
        if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Удалить',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
