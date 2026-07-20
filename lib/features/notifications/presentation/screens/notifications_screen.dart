import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/features/notifications/data/models/notification_item.dart';
import 'package:optombai/features/notifications/presentation/logic/notifications_cubit.dart';
import 'package:optombai/utils/extensions/iso_date_extension.dart';
import 'package:optombai/utils/extensions/url_string_extension.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/live_ring_avatar.dart';

@RoutePage()
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsCubit>().loadFirstPage();
    });
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<NotificationsCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final Color fg = isDark ? Colors.white : Colors.black;
    final Color sub = isDark ? Colors.white : Colors.grey.shade800;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : null,
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -11,
        passive: true,
      ),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: isDark ? Colors.black : null,
        foregroundColor: fg,
        title: TextTranslated(
          'Уведомления',
          style: TextStyle(fontWeight: FontWeight.w700, color: fg),
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            buildWhen: (p, c) => p.unreadCount != c.unreadCount,
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllRead(),
                child: const TextTranslated(
                  'Прочитать все',
                  style: TextStyle(fontSize: 13),
                ),
              );
            },
          ),
          /*IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                context.router.push(const NotificationPreferencesRoute()),
          ),*/
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state.status == NotificationsStatus.loading &&
              state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NotificationsStatus.error &&
              state.items.isEmpty) {
            return Center(
              child: TextTranslated(
                state.errorMessage ?? 'Не удалось загрузить',
                style: TextStyle(color: fg),
              ),
            );
          }
          if (state.items.isEmpty) {
            return Center(
              child: TextTranslated(
                'Пока нет уведомлений',
                style: TextStyle(color: fg),
              ),
            );
          }

          final rows = _buildRows(state.items);

          return RefreshIndicator(
            onRefresh: () => context.read<NotificationsCubit>().loadFirstPage(),
            child: ListView.builder(
              controller: _controller,
              padding: EdgeInsets.only(bottom: 16.h),
              itemCount: rows.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= rows.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final row = rows[index];
                final header = row.header;
                if (header != null) {
                  return _SectionHeader(title: header, isDark: isDark);
                }

                final item = row.item!;
                final canOpenProfile = item.actorId?.isNotEmpty ?? false;
                return _NotificationTile(
                  item: item,
                  showDivider: row.divider,
                  fg: fg,
                  sub: sub,
                  isDark: isDark,
                  onTap: () => _onTapItem(context, item),
                  onAvatarTap:
                      canOpenProfile ? () => _openProfile(context, item) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<_Row> _buildRows(List<NotificationItem> items) {
    final rows = <_Row>[];
    String? currentBucket;
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final bucket = _bucketFor(it.createdAt.toLocal());
      if (bucket != currentBucket) {
        rows.add(_Row.header(bucket));
        currentBucket = bucket;
      }
      final hasNextSameBucket = i + 1 < items.length &&
          _bucketFor(items[i + 1].createdAt.toLocal()) == bucket;
      rows.add(_Row.item(it, divider: hasNextSameBucket));
    }
    return rows;
  }

  static String _bucketFor(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff <= 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    if (diff < 7) return 'На этой неделе';
    return 'Ранее';
  }

  Future<void> _onTapItem(
    BuildContext context,
    NotificationItem item,
  ) async {
    final cubit = context.read<NotificationsCubit>();
    if (!item.isRead) {
      cubit.markAsRead(item.id);
    }

    switch (item.type) {
      case NotificationType.like:
      case NotificationType.comment:
        await _openPublication(
          context,
          item.postId,
          commentId:
              item.type == NotificationType.comment ? item.commentId : null,
        );
        break;
      case NotificationType.unknown:
      case NotificationType.message:
        break;
    }
  }

  void _openProfile(BuildContext context, NotificationItem item) {
    final id = item.actorId;
    if (id == null || id.isEmpty) return;
    context.router.push(
      OtherUserProfileRoute(
        user: id,
        username: item.actorUsername ?? '',
      ),
    );
  }

  Future<void> _openPublication(
    BuildContext context,
    String? postId, {
    String? commentId,
  }) async {
    if (postId == null || postId.isEmpty) return;

    final router = context.router;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final product = await getIt<IProductRepository>().getProductInfo(postId);
      navigator.pop();
      if (!mounted) return;
      router.push(ProductDetailsRoute(results: product, commentId: commentId));
    } catch (_) {
      navigator.pop();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: TextTranslated('Не удалось открыть публикацию'),
        ),
      );
    }
  }
}

class _Row {
  final String? header;
  final NotificationItem? item;
  final bool divider;

  const _Row.header(this.header)
      : item = null,
        divider = false;

  const _Row.item(this.item, {this.divider = false}) : header = null;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 6.h),
      child: TextTranslated(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
    required this.fg,
    required this.sub,
    required this.isDark,
    this.onAvatarTap,
    this.showDivider = true,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback? onAvatarTap;
  final bool showDivider;
  final Color fg;
  final Color sub;
  final bool isDark;

  bool get _showPreview => item.type.belongsToNotifications;

  @override
  Widget build(BuildContext context) {
    final hasUser =
        item.actorUsername != null && item.actorUsername!.trim().isNotEmpty;
    final String name = hasUser ? item.actorUsername!.trim() : item.title;
    final String message = switch (item.type) {
      NotificationType.like => 'Лайкнул вашу публикацию',
      NotificationType.comment => 'Прокомментировал вашу публикацию',
      _ => item.body.isNotEmpty ? item.body : (hasUser ? item.title : ''),
    };

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NotificationAvatar(
                  item: item,
                  onTap: onAvatarTap,
                  isDark: isDark,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      if (message.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: sub,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          _relativeTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showPreview) ...[
                  SizedBox(width: 12.w),
                  _NotificationPreview(item: item, isDark: isDark),
                ],
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 0.6,
              indent: 16.w + 40 + 12.w,
              endIndent: 16.w,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.grey.withValues(alpha: 0.20),
            ),
        ],
      ),
    );
  }

  String get _relativeTime {
    // Shared fresh-timestamp wording ("только что" / "N минут назад" / …),
    // same as product details; absolute date past 7 days.
    final relative = item.createdAt.asRecentRelativeTime;
    if (relative != null) return relative;

    final dt = item.createdAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.day} ${_monthsGenitive[dt.month - 1]}, '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  static const List<String> _monthsGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
}

/// Avatar of the action author. Shows `actor.image`, falling back to the first
/// letter of the username, then to a type icon.
class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({
    required this.item,
    required this.isDark,
    this.onTap,
  });

  final NotificationItem item;
  final bool isDark;

  /// Opens the action author's profile. Null when the author id is unknown,
  /// leaving the tap to bubble up to the row (which opens the publication).
  final VoidCallback? onTap;

  IconData get _typeIcon {
    switch (item.type) {
      case NotificationType.like:
        return Icons.favorite_border;
      case NotificationType.comment:
        return Icons.mode_comment_outlined;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.unknown:
        return Icons.notifications_none;
    }
  }

  static const _ring = LinearGradient(
    colors: [Colors.red, Colors.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Widget _ringed(Widget avatar) => Container(
        padding: const EdgeInsets.all(2),
        decoration:
            const BoxDecoration(shape: BoxShape.circle, gradient: _ring),
        child: avatar,
      );

  @override
  Widget build(BuildContext context) {
    final image = item.actorImage;
    final username = item.actorUsername;
    final Color bgColor =
        isDark ? const Color(0xff2A2A36) : const Color(0xffE0E0E0);
    final Color fgColor = isDark ? Colors.white : Colors.grey.shade700;
    final ownerId = item.actorId ?? '';

    if (image != null) {
      return LiveRingAvatar(
        radius: 24,
        ownerId: ownerId,
        imageUrl: image,
        onTap: onTap,
        notLiveRingBuilder: _ringed,
      );
    }

    if (username != null && username.trim().isNotEmpty) {
      return LiveRingAvatar(
        radius: 24,
        ownerId: ownerId,
        backgroundColor: bgColor,
        onTap: onTap,
        notLiveRingBuilder: _ringed,
        child: Text(
          username.trim().characters.first.toUpperCase(),
          style: TextStyle(
            color: fgColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      );
    }

    return LiveRingAvatar(
      radius: 24,
      ownerId: ownerId,
      backgroundColor: bgColor,
      onTap: onTap,
      notLiveRingBuilder: _ringed,
      child: Icon(_typeIcon, color: fgColor, size: 18),
    );
  }
}

/// Media preview of the targeted publication. Renders `cover_url` when present,
/// a placeholder otherwise, and a ▶ overlay for videos.
class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.item, required this.isDark});

  final NotificationItem item;
  final bool isDark;

  static const double _size = 54;

  @override
  Widget build(BuildContext context) {
    final url = item.previewUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              CachedNetworkImage(
                imageUrl: url.ensureHttpsPrefix(),
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder,
                errorWidget: (_, __, ___) => _placeholder,
              )
            else
              _placeholder,
            if (item.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget get _placeholder => Container(
        color: isDark ? const Color(0xff2A2A36) : const Color(0xffE9E9E9),
        child: Icon(
          item.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
          color: isDark ? Colors.white70 : Colors.grey.shade500,
          size: 20,
        ),
      );
}
