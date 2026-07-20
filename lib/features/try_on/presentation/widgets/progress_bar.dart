import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final int progress;

  const ProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress / 100,
        minHeight: 10,
        backgroundColor: Colors.grey.shade300,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
