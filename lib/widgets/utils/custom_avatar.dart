import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAvatar extends StatelessWidget {
  final double? width;
  final double? height;
  final double? size;
  final double? sizeAvatar;
  final Color colorContainerBorder;
  final Color colorContainer;
  final Widget? child;
  final String? image;

  const CustomAvatar(
      {super.key,
      this.width,
      this.height,
      required this.colorContainerBorder,
      required this.colorContainer,
      this.size,
      this.child,
      required this.image,
      this.sizeAvatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorContainer,
        border: Border.all(color: colorContainerBorder, width: 0.2.w),
        shape: BoxShape.circle,
      ),
      child: child ??
          (image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: CachedNetworkImage(
                    imageUrl: image!,
                    // Decode at display size, not source resolution.
                    memCacheWidth: 150,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ))
              : const Image(image: AssetImage('assets/icons/profile.png'))),
    );
  }
}
