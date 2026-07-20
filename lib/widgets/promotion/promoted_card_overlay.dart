import 'package:flutter/material.dart';

/// Overlay that stamps a small "Реклама" pill in the top-left corner of
/// any card-like child. Top-left (not top-right) to avoid colliding with
/// each card's own save/favorite icon, which every feed card places at
/// top-right — same corner convention as the "Продвигается" badge in
/// `product_card.dart`.
class PromotedCardOverlay extends StatelessWidget {
  const PromotedCardOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // return Stack(
    //   children: [
    //     child,
    //     const Positioned(
    //       top: 6,
    //       left: 6,
    //       child: _PromotedBadge(),
    //     ),
    //   ],
    // );
    return child;
  }
}

// ignore: unused_element
class _PromotedBadge extends StatelessWidget {
  const _PromotedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Реклама',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
