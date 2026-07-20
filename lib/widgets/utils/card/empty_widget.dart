import 'package:flutter/material.dart';

class EmptyImageWidget extends StatelessWidget {
  const EmptyImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: const Image(
        image: AssetImage("assets/notfound.png"),
        fit: BoxFit.cover,
      ),
    );
  }
}
