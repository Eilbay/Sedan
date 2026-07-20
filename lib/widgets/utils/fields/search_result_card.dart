import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/data/models/posts/post_model.dart';

class SearchResultCard extends StatelessWidget {
  final Product product;

  const SearchResultCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final productImage = product.previewUrl;
    final isVideo = product.image_post.isNotEmpty && product.image_post.first.isVideo;

    final avatarUrl = product.owner?.image;
    final ownerName = product.owner?.username ?? 'Продавец';

    return ListTile(
      onTap: () {
        context.router.push(ProductDetailsRoute(results: product));
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: productImage != null
            ? Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: productImage,
                    // Decode at display size, not source resolution.
                    memCacheWidth: 150,
                    width: 50.w,
                    height: 50.h,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50.w,
                      height: 50.h,
                      color: Colors.grey.shade200,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.w)),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                  if (isVideo)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Container(
                width: 50.w,
                height: 50.h,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported),
              ),
      ),
      title: Row(
        children: [
          if (avatarUrl != null)
            CircleAvatar(
              radius: 10,
              backgroundImage: CachedNetworkImageProvider(avatarUrl),
              backgroundColor: Colors.grey.shade200,
            ),
          if (avatarUrl != null) SizedBox(width: 6.w),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          const Icon(
            Icons.person,
            size: 14,
            color: Colors.black,
          ),
          SizedBox(width: 5.w),
          Text(ownerName,
              style: const TextStyle(fontSize: 13, color: Colors.black)),
          SizedBox(width: 10.w),
          const Icon(Icons.star, size: 14, color: Colors.amber),
          SizedBox(width: 4.w),
          Text('${product.rating}',
              style: const TextStyle(fontSize: 13, color: Colors.black)),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            product.currency,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          SizedBox(height: 4.h),
          Text(
            "#${product.productNumber.toString()}",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
