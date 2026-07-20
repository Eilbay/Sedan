import 'package:flutter/material.dart';

class ReviewStars extends StatefulWidget {
  final bool active;
  final VoidCallback callback;

  const ReviewStars({super.key, required this.active, required this.callback});

  @override
  State<ReviewStars> createState() => _ReviewIconState();
}

class _ReviewIconState extends State<ReviewStars> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.callback,
      icon: Icon(
        Icons.star,
        size: 36,
        color:
        !widget.active ? const Color(0xffEAE8EB) : const Color(0xffFFA800),
      ),
    );
  }
}