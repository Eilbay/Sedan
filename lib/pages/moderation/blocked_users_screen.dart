import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/block/block_model.dart';
import 'package:optombai/widgets/app_scaffold/custom_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/message_show.dart';

@RoutePage()
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BlockBloc>().add(const LoadBlocksEvent(forceRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);
    return CustomScaffold(
      title: 'Заблокированные',
      bottomNavigationBar:
          const BottomNav(currentIndexOverride: -1, passive: true),
      child: BlocConsumer<BlockBloc, BlockState>(
        listenWhen: (prev, curr) =>
            prev.justUnblockedUserId != curr.justUnblockedUserId ||
            prev.errors != curr.errors,
        listener: (ctx, state) {
          if (state.justUnblockedUserId.isNotEmpty) {
            showMessage(
              ctx,
              const ['Пользователь разблокирован'],
              EnumStatusMessage.success,
            );
            ctx.read<BlockBloc>().add(const ResetBlockStatusEvent());
          } else if (state.errors.isNotEmpty) {
            showMessage(ctx, state.errors, EnumStatusMessage.error);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.results.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.results.isEmpty) {
            return _EmptyState(isDarkMode: isDarkMode);
          }
          return RefreshIndicator(
            onRefresh: () async => context
                .read<BlockBloc>()
                .add(const LoadBlocksEvent(forceRefresh: true)),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              itemCount: state.results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final block = state.results[index];
                return _BlockedUserTile(
                  block: block,
                  isDarkMode: isDarkMode,
                  onUnblock: () => context
                      .read<BlockBloc>()
                      .add(UnblockUserEvent(userId: block.blocked.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final BlockModel block;
  final bool isDarkMode;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.block,
    required this.isDarkMode,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          _Avatar(image: block.blocked.image),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.blocked.username,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if ((block.reason ?? '').isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    block.reason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: textColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _UnblockButton(onPressed: onUnblock),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? image;

  const _Avatar({this.image});

  @override
  Widget build(BuildContext context) {
    final url = image ?? '';
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 22.r,
        backgroundColor: kAvatarColor,
        child: const Icon(Icons.person, color: Colors.white),
      );
    }
    return CircleAvatar(
      radius: 22.r,
      backgroundColor: kAvatarColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          // Decode at display size, not source resolution.
          memCacheWidth: 150,
          width: 44.r,
          height: 44.r,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              const Icon(Icons.person, color: Colors.white),
        ),
      ),
    );
  }
}

class _UnblockButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _UnblockButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isMutating =
        context.select((BlockBloc b) => b.state.isMutating);
    return TextButton(
      onPressed: isMutating ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: activeColor.withOpacity(0.12),
        foregroundColor: activeColor,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: TextTranslated(
        'Разблокировать',
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDarkMode;

  const _EmptyState({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDarkMode ? Colors.white70 : Colors.black54;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 48.r, color: textColor),
            SizedBox(height: 12.h),
            TextTranslated(
              'Список пуст',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 6.h),
            TextTranslated(
              'Вы пока никого не заблокировали',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
