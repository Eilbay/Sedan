import 'package:flutter/material.dart';
import 'package:optombai/widgets/shimmer/shimmer_box.dart';

/// Shimmer placeholder matching the profile's square thumbnail grid.
class ShimmerProfileGrid extends StatelessWidget {
  const ShimmerProfileGrid({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      primary: false,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 5,
        childAspectRatio: 1 / 1,
        crossAxisSpacing: 5,
      ),
      itemBuilder: (_, __) => const ShimmerBox(borderRadius: 10),
    );
  }
}
