import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class SliderDotsIndicator extends StatelessWidget {
  const SliderDotsIndicator({
    super.key,
    required this.itemCount,
    required this.carouselController,
    required this.currentIndex,
    required this.dotSize,
    required this.activeDotSize,
    required this.dotSpacing,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int itemCount;
  final CarouselSliderController? carouselController;
  final int currentIndex;
  final double dotSize;
  final double activeDotSize;
  final double dotSpacing;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: activeDotSize,
            height: activeDotSize,
            margin: EdgeInsets.symmetric(horizontal: dotSpacing),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final bool isActive = index == currentIndex;
        return GestureDetector(
          onTap: () {
            if (carouselController != null) {
              carouselController!.animateToPage(index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? activeDotSize : dotSize,
            height: isActive ? activeDotSize : dotSize,
            margin: EdgeInsets.symmetric(horizontal: dotSpacing),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}
