import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/cart_bloc/cart_bloc.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/cart/cart_item_model.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/widgets/cart/quantity_selector.dart';

/// Horizontal card for cart item
/// Matches the design mockup with image, info, favorite button and quantity selector
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onTap;

  const CartItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return Material(
      color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: SizedBox(
                  width: 60.w,
                  height: 60.w,
                  child: item.productImage != null
                      ? CachedNetworkImage(
                          imageUrl: item.productImage!,
                          // Decode at display size, not source resolution.
                          memCacheWidth: 300,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
              SizedBox(width: 8.w),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and favorite button row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Favorite button
                        _FavoriteButton(
                          productId: item.productId,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                    // Company name
                    if (item.ownerName != null)
                      Text(
                        item.ownerName!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 4.h),
                    // Price and quantity row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatPrice(item.price),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xffFFA800),
                          ),
                        ),
                        QuantitySelector(
                          quantity: item.quantity,
                          onChanged: (newQuantity) {
                            context.read<CartBloc>().add(
                                  CartUpdateQuantityEvent(
                                    itemId: item.id,
                                    quantity: newQuantity,
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.truncate()) {
      return '${price.truncate()} \u20BD';
    }
    return '${price.toStringAsFixed(2)} \u20BD';
  }
}

class _FavoriteButton extends StatelessWidget {
  final String productId;
  final bool isDarkMode;

  const _FavoriteButton({
    required this.productId,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      buildWhen: (previous, current) =>
          previous.results != current.results,
      builder: (context, state) {
        final isFavorite = _isInFavorites(state.results, productId);

        return IconButton(
          iconSize: 22,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: 32.w,
            minHeight: 32.w,
          ),
          icon: Icon(
            isFavorite ? Icons.bookmark : Icons.bookmark_border,
            color: isFavorite
                ? const Color(0xFF7B2FF2)
                : (isDarkMode ? Colors.white : Colors.grey),
          ),
          onPressed: () {
            if (isFavorite) {
              final favorite = _getFavorite(state.results, productId);
              if (favorite != null) {
                context.read<FavoriteBloc>().add(FavoriteDelete(id: favorite.id));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Откройте товар, чтобы добавить в избранное'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  bool _isInFavorites(List<FavoriteResult> favorites, String productId) {
    return favorites.any((f) => f.post.id == productId);
  }

  FavoriteResult? _getFavorite(List<FavoriteResult> favorites, String productId) {
    try {
      return favorites.firstWhere((f) => f.post.id == productId);
    } catch (_) {
      return null;
    }
  }
}
