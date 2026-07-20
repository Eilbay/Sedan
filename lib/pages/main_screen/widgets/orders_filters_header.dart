import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_bloc.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_state.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/countries/countries.dart';
import 'package:optombai/data/models/market/market_model.dart';
import 'package:optombai/widgets/utils/dropdown/category_dropdown.dart';

class OrdersFiltersHeader extends StatelessWidget {
  final int? choseOwner;
  final bool isDarkMode;
  final int? marketId;
  final int? countryId;
  final String? categoryId;
  final ValueChanged<String> onSearchSubmit;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onMarketChanged;
  final void Function(int value, String name) onCountryChanged;
  final ValueChanged<String?> onCategoryChanged;

  const OrdersFiltersHeader({
    super.key,
    required this.choseOwner,
    required this.isDarkMode,
    required this.marketId,
    required this.countryId,
    required this.categoryId,
    required this.onSearchSubmit,
    required this.onSearchChanged,
    required this.onMarketChanged,
    required this.onCountryChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (choseOwner != 4 && choseOwner != 8 && choseOwner != 16) ...[
          CustomSearchField(
            focusBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            onSubmit: onSearchSubmit,
            onChange: onSearchChanged,
          ),
        ],
        if (choseOwner == 4) ...[
          SizedBox(height: 12.h),
          _MarketFilterRow(
            marketId: marketId,
            isDarkMode: isDarkMode,
            onMarketChanged: onMarketChanged,
          ),
        ] else ...[
          SizedBox(height: 10.h),
        ],
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _CountryDropdown(
                countryId: countryId,
                onCountryChanged: onCountryChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryDropdown(
                categoryId: categoryId,
                onCategoryChanged: onCategoryChanged,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

class _MarketFilterRow extends StatelessWidget {
  final int? marketId;
  final bool isDarkMode;
  final ValueChanged<int> onMarketChanged;

  const _MarketFilterRow({
    required this.marketId,
    required this.isDarkMode,
    required this.onMarketChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierMarketBloc, SupplierMarketState>(
      buildWhen: (previous, current) =>
          previous.markets != current.markets,
      builder: (context, state) {
        final markets = List<MarketModel>.from(state.markets)
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        final label = marketId == null
            ? "Все"
            : markets
                .firstWhere(
                  (m) => m.id == marketId,
                  orElse: () => const MarketModel(id: 0, name: "Все"),
                )
                .name;

        return Row(
          children: [
            const Text(
              "Сортировка по рынкам:",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<int>(
              icon: Icon(Icons.tune,
                  size: 22,
                  color: isDarkMode ? Colors.white : Colors.black87),
              position: PopupMenuPosition.under,
              elevation: 6,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: onMarketChanged,
              itemBuilder: (context) {
                final items = <PopupMenuEntry<int>>[];

                items.add(_compactItem(
                  value: 0,
                  title: "Все",
                  selected: marketId == null,
                ));

                for (final m in markets) {
                  items.add(_compactItem(
                    value: m.id,
                    title: m.name,
                    selected: marketId == m.id,
                  ));
                }

                return items;
              },
            ),
          ],
        );
      },
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  final int? countryId;
  final void Function(int value, String name) onCountryChanged;

  const _CountryDropdown({
    required this.countryId,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CountryBloc, CountryState>(
      listener: (context, state) {},
      builder: (context, countryState) {
        final countries = <CountryModel>[
          const CountryModel(id: 0, name: "Все страны"),
          ...countryState.list,
        ];

        final selectedValue = countryId ?? 0;

        return CustomDropdown(
          title: "Страна",
          titleSize: 16,
          itemSize: 17,
          list: countries,
          value: selectedValue,
          onChanged: (value) {
            final name = (value == 0)
                ? "Все страны"
                : countries
                    .firstWhere((c) => c.id == value,
                        orElse: () => const CountryModel(id: 0, name: ''))
                    .name;
            onCountryChanged(value, name);
          },
        );
      },
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? categoryId;
  final ValueChanged<String?> onCategoryChanged;

  const _CategoryDropdown({
    required this.categoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      buildWhen: (previous, current) =>
          previous.categories != current.categories,
      builder: (context, catState) {
        final filteredCategories = catState.categories.where((category) {
          final name = category.name.toLowerCase();
          return !name.contains('статус') && !name.contains('склад');
        }).toList();

        final categories = <Category>[
          const Category(
            id: 'all',
            name: 'Все категории',
            icon: '',
            children: [],
          ),
          ...filteredCategories,
        ];

        final selectedValue = categoryId ?? 'all';

        return CustomCategoryDropdown(
          list: categories,
          value: selectedValue,
          hint: 'Категории',
          onChanged: onCategoryChanged,
        );
      },
    );
  }
}

PopupMenuItem<int> _compactItem({
  required int value,
  required String title,
  required bool selected,
}) {
  return PopupMenuItem<int>(
    value: value,
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
        if (selected) const Icon(Icons.check, size: 18, color: Colors.blue),
      ],
    ),
  );
}
