import 'package:flutter/material.dart';

class Stars extends StatelessWidget {
  final double rating;

  const Stars({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(
        5,
            (index) {
          if (rating >= index + 1) {
            return const Icon(
              Icons.star,
              size: 15,
              color: Color(0xffFFA800),
            );
          } else if (rating > index && rating < index + 1) {
            return const Icon(
              Icons.star_half,
              size: 15,
              color: Color(0xffFFA800),
            );
          } else {
            return const Icon(
              Icons.star_border,
              size: 15,
              color: Color(0xffFFA800),
            );
          }
        },
      ),
    );
  }
}

