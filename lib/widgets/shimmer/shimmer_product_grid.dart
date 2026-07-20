import 'package:flutter/material.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_card.dart';

/// Shimmer placeholder for a grid of product cards.
class ShimmerProductGrid extends StatelessWidget {
  const ShimmerProductGrid({
    super.key,
    this.itemCount = 6,
    this.gridDelegate,
  });

  final int itemCount;
  final SliverGridDelegate? gridDelegate;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return GridView.builder(
      primary: false,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: gridDelegate ??
          SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisSpacing: 18,
            crossAxisSpacing: 10,
            childAspectRatio: (screenWidth * .2) / 200,
          ),
      itemBuilder: (_, __) => const ShimmerProductCard(),
    );
  }
}
