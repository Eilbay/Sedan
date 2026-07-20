import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/utils/extensions/int_format_extension.dart';

class ReelGridCard extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onTap;

  const ReelGridCard({
    super.key,
    required this.reel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: reel.coverUrl != null && reel.coverUrl!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: reel.coverUrl!,
                        // Decode at display size, not source resolution.
                        memCacheWidth: 400,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.black,
                          child: Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              size: 50.sp,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          size: 50.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 50.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80.h,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8.h,
            left: 8.w,
            right: 8.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reel.description.isNotEmpty)
                  Text(
                    reel.description,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      reel.views.toCompactFormat(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.favorite,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      reel.likes.toCompactFormat(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (reel.isPromoted &&
              (reel.promoEndAt?.isAfter(DateTime.now()) ?? false))
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff0095D5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 10,
                      color: Colors.white,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Продвигается',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 8.h,
            right: 8.w,
            child: Column(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.grey[700],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.w),
                    child: reel.owner.image != null &&
                            reel.owner.image!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: reel.owner.image!,
                            memCacheWidth: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[700],
                            ),
                            // Same no-photo placeholder as user cards.
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/icons/profile.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/icons/profile.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                if (reel.owner.country != null &&
                    reel.owner.country!.circleFlag != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      reel.owner.country!.circleFlag!,
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
