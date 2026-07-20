import 'package:flutter/material.dart';

/// Reusable page number button for pagination controls.
class PageButton extends StatelessWidget {
  final int page;
  final int currentPage;
  final ValueChanged<int> onPageSelected;

  const PageButton({
    super.key,
    required this.page,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = currentPage == page;

    return GestureDetector(
      onTap: () => onPageSelected(page),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          border: Border.all(color: Colors.blue, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.blue,
          ),
        ),
      ),
    );
  }
}
