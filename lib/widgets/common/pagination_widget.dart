import 'package:flutter/material.dart';
import 'package:optombai/widgets/common/page_button.dart';

/// Reusable pagination controls with page buttons, ellipsis, and nav arrows.
class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;
  final bool isBusy;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    // When the result fits on a single page (or there are no results)
    // there's nothing to paginate — drawing a lone "1" button is just
    // visual noise that confuses users into thinking more pages exist.
    if (totalPages <= 1) return const SizedBox.shrink();

    final List<Widget> pageButtons = [];

    if (currentPage > 1) {
      pageButtons.add(
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.blue, size: 20),
          onPressed: () => onPageSelected(currentPage - 1),
        ),
      );
    }

    pageButtons.add(PageButton(
      page: 1,
      currentPage: currentPage,
      onPageSelected: onPageSelected,
    ));

    if (currentPage > 3) {
      if (currentPage > 4) {
        pageButtons.add(_ellipsis);
      } else {
        pageButtons.add(PageButton(
          page: 2,
          currentPage: currentPage,
          onPageSelected: onPageSelected,
        ));
      }
    }

    int start = currentPage - 1;
    int end = currentPage + 1;
    if (start < 2) start = 2;
    if (end > totalPages - 1) end = totalPages - 1;

    for (int i = start; i <= end; i++) {
      pageButtons.add(PageButton(
        page: i,
        currentPage: currentPage,
        onPageSelected: onPageSelected,
      ));
    }

    if (currentPage < totalPages - 2) {
      if (currentPage < totalPages - 3) {
        pageButtons.add(_ellipsis);
      } else {
        pageButtons.add(PageButton(
          page: totalPages - 1,
          currentPage: currentPage,
          onPageSelected: onPageSelected,
        ));
      }
    }

    if (totalPages > 1) {
      pageButtons.add(PageButton(
        page: totalPages,
        currentPage: currentPage,
        onPageSelected: onPageSelected,
      ));
    }

    if (currentPage < totalPages) {
      pageButtons.add(
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.blue, size: 20),
          onPressed: () => onPageSelected(currentPage + 1),
        ),
      );
    }

    final row = Row(mainAxisSize: MainAxisSize.min, children: pageButtons);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              ignoring: isBusy,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: row,
              ),
            ),
            if (isBusy)
              const Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _ellipsis = Padding(
    padding: EdgeInsets.symmetric(horizontal: 6),
    child: Text("...", style: TextStyle(fontSize: 18)),
  );
}
