import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/utils/extensions/url_string_extension.dart';

/// Circular avatar wrapped in the brand gradient ring (red → purple), matching
/// the profile header treatment. Single source of truth for avatar rings in
/// notification / chat lists, so the look stays consistent across screens.
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    super.key,
    required this.radius,
    this.imageUrl,
    this.backgroundColor = const Color(0xffF0F0F0),
    this.child,
    this.onTap,
  });

  /// Radius of the inner avatar (the gradient ring sits outside it).
  final double radius;
  final String? imageUrl;
  final Color backgroundColor;

  /// Fallback content shown when [imageUrl] is null (initial letter / icon).
  final Widget? child;

  /// When non-null, the avatar becomes tappable (e.g. open author profile).
  final VoidCallback? onTap;

  static const Gradient _ring = LinearGradient(
    colors: [Colors.red, Colors.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final image = imageUrl;
    final avatar = Container(
      padding: EdgeInsets.all(2.w),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: _ring,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: image != null
            ? CachedNetworkImageProvider(image.ensureHttpsPrefix())
            : null,
        child: image == null ? child : null,
      ),
    );

    if (onTap == null) return avatar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: avatar,
    );
  }
}
