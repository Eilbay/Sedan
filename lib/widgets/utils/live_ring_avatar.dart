import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:optombai/features/live_stream/presentation/logic/live_stream_navigator.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/utils/extensions/url_string_extension.dart';

/// Circular avatar that grows a red "on air" ring + badge when [ownerId] is
/// currently live-streaming (Instagram-style), tapping into their live room
/// instead of the normal [onTap] destination. Falls back to a plain avatar
/// (no ring) when the owner isn't live — callers that already show their own
/// decorative ring (e.g. [GradientAvatar]) should keep using that when not
/// live and only reach for this widget where a live indicator is wanted.
class LiveRingAvatar extends StatelessWidget {
  const LiveRingAvatar({
    super.key,
    required this.radius,
    required this.ownerId,
    this.imageUrl,
    this.backgroundColor = const Color(0xffF0F0F0),
    this.child,
    this.onTap,
    this.notLiveRingBuilder,
  });

  final double radius;
  final String ownerId;
  final String? imageUrl;
  final Color backgroundColor;

  /// Fallback content shown when [imageUrl] is null (initial letter / icon).
  final Widget? child;

  /// Tap target used when the owner is NOT currently live.
  final VoidCallback? onTap;

  /// Wraps the plain avatar with a caller-specific decorative ring when the
  /// owner is NOT live (e.g. the profile header's permanent red→purple
  /// ring). Left null, the avatar renders with no ring when not live.
  final Widget Function(Widget avatar)? notLiveRingBuilder;

  static const _liveColor = Color(0xFFFF004D);

  @override
  Widget build(BuildContext context) {
    final stream = context.select(
      (StreamCubit cubit) => cubit.state.liveStreamForOwner(ownerId),
    );

    final image = imageUrl;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: image != null
          ? CachedNetworkImageProvider(image.ensureHttpsPrefix())
          : null,
      child: image == null ? child : null,
    );

    if (stream == null) {
      final ringedAvatar = notLiveRingBuilder?.call(avatar) ?? avatar;
      if (onTap == null) return ringedAvatar;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ringedAvatar,
      );
    }

    final ringWidth = (radius * 0.14).clamp(2.0, 3.0);
    final badgeFontSize = (radius * 0.3).clamp(8.0, 11.0);
    final badgeIconSize = badgeFontSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => const LiveStreamNavigator().openRoom(context, stream),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            padding: EdgeInsets.all(ringWidth),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _liveColor,
            ),
            child: avatar,
          ),
          Positioned(
            bottom: -badgeFontSize * 0.7,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: badgeFontSize * 0.5,
                vertical: badgeFontSize * 0.15,
              ),
              decoration: BoxDecoration(
                color: _liveColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/live_broadcast.svg',
                    width: badgeIconSize,
                    height: badgeIconSize,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  SizedBox(width: badgeFontSize * 0.25),
                  Text(
                    "эфир",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
