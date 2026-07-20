import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:provider/provider.dart';

class AboutUsCard extends StatelessWidget {
  final User user;
  final bool isCurrentUser;

  const AboutUsCard({
    super.key,
    required this.user,
    required this.isCurrentUser,
  });

  String _yesNo(dynamic v) => (v == true) ? "Да" : "Нет";

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final data = user.about_us_data ?? <String, dynamic>{};
    final type = user.userType ?? "";

    List<MapEntry<String, String>> items = [];
    if (type == "4") {
      items = [
        MapEntry("Вы являетесь", (data["supplier_kind"] ?? "").toString()),
        MapEntry("Склад в наличии", _yesNo(data["has_stock"])),
        MapEntry("Минимальный опт. заказ",
            (data["min_wholesale_order"] ?? "").toString()),
        MapEntry("Дропшиппинг", _yesNo(data["dropshipping"])),
        MapEntry("Официально", _yesNo(data["official_work"])),
        MapEntry("Экспорт в РФ", _yesNo(data["export_docs_rf"])),
        MapEntry("Экспорт в Европу", _yesNo(data["export_docs_eu"])),
        MapEntry("Гарантия качества", _yesNo(data["quality_guarantee"])),
      ];
    } else if (type == "8") {
      if ((user.manufacturer_segment ?? "") == "clothing") {
        items = [
          MapEntry("Количество сотрудников",
              (data["employees_count"] ?? "").toString()),
          MapEntry("Размерная сетка", (data["size_grid"] ?? "").toString()),
          MapEntry("Минимальный заказ (шт)",
              (data["min_order_units"] ?? "").toString()),
          MapEntry("Официально", _yesNo(data["official_work"])),
          MapEntry("Экспорт в РФ", _yesNo(data["export_docs_rf"])),
          MapEntry("Экспорт в Европу", _yesNo(data["export_docs_eu"])),
          MapEntry("Гарантия качества", _yesNo(data["quality_guarantee"])),
        ];
      } else {
        items = [
          MapEntry(
              "Тип производства", (data["production_type"] ?? "").toString()),
          MapEntry("Количество сотрудников",
              (data["employees_count"] ?? "").toString()),
          MapEntry("MOQ", (data["moq"] ?? "").toString()),
          MapEntry("White label", _yesNo(data["white_label"])),
          MapEntry("Сертификация", _yesNo(data["certification"])),
          MapEntry("Официально", _yesNo(data["official_work"])),
          MapEntry("Экспорт в РФ", _yesNo(data["export_docs_rf"])),
          MapEntry("Экспорт в Европу", _yesNo(data["export_docs_eu"])),
          MapEntry("Гарантия качества", _yesNo(data["quality_guarantee"])),
        ];
      }
    }

    final bgCard = isDark ? const Color(0xff101A29) : const Color(0xffEDF3FF);
    final bgInner = isDark ? const Color(0xff0E1E33) : Colors.white;
    const divider = Color(0xffCFDEFB);
    final labelColor =
        isDark ? const Color(0xffAEB7C6) : const Color(0xff7F7F7F);
    final iconColor =
        isDark ? const Color(0xffAEB7C6) : const Color(0xC95F5F5F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: bgCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: TextTranslated(
                  "О нас",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ),
              if (isCurrentUser)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context.router.push(
                    AboutUsEditRoute(user: user)),
                  icon: Icon(
                    Icons.drive_file_rename_outline_rounded,
                    color: iconColor,
                  ),
                ),
            ],
          ),
          if (user.about_us.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            TextTranslated(
              user.about_us.trim(),
              style: TextStyle(
                height: 1.35,
                color: isDark ? Colors.white.withValues(alpha: .92) : Colors.black87,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            TextTranslated(
              "Информация не заполнена",
              style: TextStyle(color: labelColor),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: bgInner,
              ),
              child: _InfoList(
                items: items,
                dividerColor: divider,
                labelColor: labelColor,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoList extends StatelessWidget {
  final List<MapEntry<String, String>> items;
  final Color dividerColor;
  final Color labelColor;
  final bool isDark;

  const _InfoList({
    required this.items,
    required this.dividerColor,
    required this.labelColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(items.length, (i) {
        final e = items[i];
        final isLast = i == items.length - 1;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextTranslated(
                e.key,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              TextTranslated(
                e.value.isEmpty ? "—" : e.value,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? Colors.white.withValues(alpha: .92) : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: dividerColor),
              ],
            ],
          ),
        );
      }),
    );
  }
}
