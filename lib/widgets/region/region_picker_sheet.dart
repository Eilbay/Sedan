import 'package:flutter/material.dart';
import 'package:optombai/data/models/region/kg_region.dart';

class RegionPickerSheet extends StatelessWidget {
  const RegionPickerSheet._({required this.selected});

  final KgRegion? selected;

  /// Shows a bottom sheet and returns the selected [KgRegion], or null if dismissed.
  static Future<KgRegion?> show(BuildContext context, {KgRegion? current}) {
    return showModalBottomSheet<KgRegion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => RegionPickerSheet._(selected: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Выберите регион',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: KgRegion.all.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              itemBuilder: (_, i) {
                final region = KgRegion.all[i];
                final isSelected = region == selected;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  title: Text(
                    region.title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFF004D) : textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: Color(0xFFFF004D), size: 20)
                      : null,
                  onTap: () => Navigator.of(context).pop(region),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewPadding.bottom + 16),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Все регионы',
                style: TextStyle(
                  fontSize: 15,
                  color: subtitleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
