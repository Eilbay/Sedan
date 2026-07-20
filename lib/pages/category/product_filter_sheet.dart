import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/data/models/market/market_model.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/pages/main_screen/main_screen.dart';
import 'package:optombai/widgets/region/region_picker_sheet.dart';

class ProductFilterConfig {
  final String? search;
  final String? filterCategoryId;
  final String? filterCategoryTitle;
  final int? regionId;

  final int? marketId;

  final String? priceGte;
  final String? priceLte;
  final String currency;
  final int sortIndex;
  final int? choseMain;
  final int? choseOwner;

  const ProductFilterConfig({
    this.search,
    this.filterCategoryId,
    this.filterCategoryTitle,
    this.regionId,
    this.marketId,
    this.priceGte,
    this.priceLte,
    this.currency = 'KGS',
    this.sortIndex = 0,
    this.choseMain = 2,
    this.choseOwner,
  });

  bool get hasActiveFilters =>
      search != null ||
      filterCategoryId != null ||
      regionId != null ||
      marketId != null ||
      (priceGte != null && priceGte!.isNotEmpty) ||
      (priceLte != null && priceLte!.isNotEmpty) ||
      sortIndex != 0;

  ProductFilterConfig copyWith({
    Object? search = _sentinel,
    Object? filterCategoryId = _sentinel,
    Object? filterCategoryTitle = _sentinel,
    Object? regionId = _sentinel,
    Object? marketId = _sentinel,
    Object? priceGte = _sentinel,
    Object? priceLte = _sentinel,
    String? currency,
    int? sortIndex,
    Object? choseMain = _sentinel,
    Object? choseOwner = _sentinel,
  }) {
    return ProductFilterConfig(
      search: search == _sentinel ? this.search : search as String?,
      filterCategoryId: filterCategoryId == _sentinel
          ? this.filterCategoryId
          : filterCategoryId as String?,
      filterCategoryTitle: filterCategoryTitle == _sentinel
          ? this.filterCategoryTitle
          : filterCategoryTitle as String?,
      regionId: regionId == _sentinel ? this.regionId : regionId as int?,
      marketId: marketId == _sentinel ? this.marketId : marketId as int?,
      priceGte: priceGte == _sentinel ? this.priceGte : priceGte as String?,
      priceLte: priceLte == _sentinel ? this.priceLte : priceLte as String?,
      currency: currency ?? this.currency,
      sortIndex: sortIndex ?? this.sortIndex,
      choseMain: choseMain == _sentinel ? this.choseMain : choseMain as int?,
      choseOwner:
          choseOwner == _sentinel ? this.choseOwner : choseOwner as int?,
    );
  }
}

const _sentinel = Object();

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet._({
    required this.config,
    required this.currentCategoryTitle,
    required this.sortOptions,
    required this.categories,
    required this.markets,
    this.totalCount,
  });

  final ProductFilterConfig config;
  final String currentCategoryTitle;
  final List<SortModel> sortOptions;
  final List<Category> categories;
  final List<MarketModel> markets;
  final int? totalCount;

  static Future<ProductFilterConfig?> show(
    BuildContext context, {
    required ProductFilterConfig config,
    required String categoryTitle,
    required List<SortModel> sortOptions,
    required List<Category> categories,
    List<MarketModel> markets = const [],
    int? totalCount,
  }) {
    return Navigator.of(context).push<ProductFilterConfig>(
      MaterialPageRoute<ProductFilterConfig>(
        fullscreenDialog: true,
        builder: (_) => ProductFilterSheet._(
          config: config,
          currentCategoryTitle: categoryTitle,
          sortOptions: sortOptions,
          categories: categories,
          markets: markets,
          totalCount: totalCount,
        ),
      ),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late ProductFilterConfig _config;
  late final TextEditingController _searchCtrl;
  late final TextEditingController _priceFromCtrl;
  late final TextEditingController _priceToCtrl;

  static const _accent = Color(0xFF7B2FF2);

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _searchCtrl = TextEditingController(text: _config.search ?? '');
    _priceFromCtrl = TextEditingController(text: _config.priceGte ?? '');
    _priceToCtrl = TextEditingController(text: _config.priceLte ?? '');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _priceFromCtrl.dispose();
    _priceToCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    _searchCtrl.clear();
    _priceFromCtrl.clear();
    _priceToCtrl.clear();
    setState(() => _config = const ProductFilterConfig());
  }

  void _apply() => Navigator.of(context).pop(_config);

  KgRegion? get _selectedRegion => KgRegion.fromId(_config.regionId);

  Future<void> _pickLocation() async {
    final selected = await RegionPickerSheet.show(
      context,
      current: _selectedRegion,
    );
    if (!mounted) return;
    setState(() {
      _config = _config.copyWith(regionId: selected?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final labelColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final hintColor = isDark ? Colors.white38 : const Color(0xFF8E8E93);
    final fieldBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E5EA);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: labelColor, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Фильтр',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _clear,
            child: const Text(
              'Очистить',
              style: TextStyle(color: _accent, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(fieldBg, hintColor),
                  if (widget.markets.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildMarketStrip(labelColor, hintColor, fieldBg, isDark),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionLabel('Категория', labelColor),
                  const SizedBox(height: 8),
                  _buildCategoryRow(labelColor, hintColor, fieldBg),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Регион', labelColor),
                  const SizedBox(height: 8),
                  _buildLocationRow(labelColor, hintColor, fieldBg),
                  const SizedBox(height: 24),
                  _buildPriceSection(
                      labelColor, hintColor, bgColor, borderColor),
                  const SizedBox(height: 24),
                  _buildSortSection(labelColor, borderColor),
                ],
              ),
            ),
          ),
          _buildApplyButton(bottomPad),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _buildMarketStrip(
    Color labelColor,
    Color hintColor,
    Color fieldBg,
    bool isDark,
  ) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: widget.markets.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _MarketTile(
              label: 'Все',
              isSelected: _config.marketId == null,
              fieldBg: fieldBg,
              labelColor: labelColor,
              accent: _accent,
              isDark: isDark,
              iconChild:
                  Icon(Icons.grid_view_rounded, color: _accent, size: 26),
              onTap: () => setState(() {
                _config = _config.copyWith(marketId: null);
              }),
            );
          }

          final market = widget.markets[index - 1];
          final selected = _config.marketId == market.id;
          return _MarketTile(
            label: market.name,
            isSelected: selected,
            fieldBg: fieldBg,
            labelColor: labelColor,
            accent: _accent,
            isDark: isDark,
            imageUrl: market.image,
            onTap: () => setState(() {
              _config = _config.copyWith(
                marketId: selected ? null : market.id,
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(Color fieldBg, Color hintColor) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) {
        _config = _config.copyWith(search: v.isEmpty ? null : v);
      },
      decoration: InputDecoration(
        hintText: 'Я ищу...',
        hintStyle: TextStyle(color: hintColor, fontSize: 15),
        prefixIcon: Icon(Icons.search, color: hintColor, size: 20),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryRow(Color labelColor, Color hintColor, Color fieldBg) {
    final title = _config.filterCategoryTitle ?? widget.currentCategoryTitle;
    final label = title.isNotEmpty ? title : 'Выбрать';
    final hasValue = title.isNotEmpty;

    return _buildFieldTile(
      label: label,
      labelColor: hasValue ? labelColor : hintColor,
      fieldBg: fieldBg,
      trailing: Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
      onTap: widget.categories.isEmpty ? null : _pickCategory,
    );
  }

  Future<void> _pickCategory() async {
    final picked = await _CategoryPickerSheet.show(
      context,
      categories: widget.categories,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _config = _config.copyWith(
        filterCategoryId: picked.id,
        filterCategoryTitle: picked.name,
      );
    });
  }

  Widget _buildLocationRow(Color labelColor, Color hintColor, Color fieldBg) {
    final region = _selectedRegion;
    return _buildFieldTile(
      label: region?.title ?? 'Выбрать регион',
      labelColor: region != null ? labelColor : hintColor,
      fieldBg: fieldBg,
      trailing: Icon(Icons.chevron_right, color: hintColor),
      onTap: _pickLocation,
    );
  }

  Widget _buildFieldTile({
    required String label,
    required Color labelColor,
    required Color fieldBg,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16, color: labelColor),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(
      Color labelColor, Color hintColor, Color inputBg, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('Цена', labelColor),
            const Spacer(),
            _buildCurrencyToggle(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPriceField(
                controller: _priceFromCtrl,
                hint: 'От 0',
                inputBg: inputBg,
                borderColor: borderColor,
                onChanged: (v) {
                  _config = _config.copyWith(priceGte: v.isEmpty ? null : v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPriceField(
                controller: _priceToCtrl,
                hint: 'До',
                inputBg: inputBg,
                borderColor: borderColor,
                onChanged: (v) {
                  _config = _config.copyWith(priceLte: v.isEmpty ? null : v);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['KGS', 'USD'].map((c) {
        final isSelected = c == _config.currency;
        return GestureDetector(
          onTap: () => setState(() {
            _config = _config.copyWith(currency: c);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.only(left: c == 'USD' ? 8 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? _accent : const Color(0xFFE5E5EA),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              c,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected ? _accent : const Color(0xFF8E8E93),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String hint,
    required Color inputBg,
    required Color borderColor,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }

  Widget _buildSortSection(Color labelColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Сортировать', labelColor),
        const SizedBox(height: 4),
        ...widget.sortOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isLast = index == widget.sortOptions.length - 1;
          return Column(
            children: [
              RadioListTile<int>(
                value: index,
                groupValue: _config.sortIndex,
                onChanged: (v) =>
                    setState(() => _config = _config.copyWith(sortIndex: v)),
                title: Text(
                  option.text,
                  style: TextStyle(color: labelColor, fontSize: 16),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: _accent,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return _accent;
                  return const Color(0xFFD1D1D6);
                }),
              ),
              if (!isLast) Divider(height: 1, color: borderColor),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildApplyButton(double bottomPad) {
    final count = widget.totalCount;
    final label =
        count != null ? 'Показать (${_formatCount(count)})' : 'Показать';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1A000000))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: _apply,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n < 1000) return n.toString();
    final groups = <String>[];
    while (n > 0) {
      groups.add((n % 1000).toString());
      n ~/= 1000;
    }
    // groups is least-significant-first; reverse to get most-significant-first
    final reversed = groups.reversed.toList();
    return [
      reversed.first,
      ...reversed.skip(1).map((g) => g.padLeft(3, '0')),
    ].join(' '); // non-breaking space as thousands separator
  }
}

class _MarketTile extends StatelessWidget {
  const _MarketTile({
    required this.label,
    required this.isSelected,
    required this.fieldBg,
    required this.labelColor,
    required this.accent,
    required this.isDark,
    required this.onTap,
    this.imageUrl,
    this.iconChild,
  });

  final String label;
  final bool isSelected;
  final Color fieldBg;
  final Color labelColor;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;
  final String? imageUrl;
  final Widget? iconChild;

  @override
  Widget build(BuildContext context) {
    const double thumb = 62;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: thumb,
              height: thumb,
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? accent : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.storefront,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    )
                  : Center(child: iconChild),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accent : labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category picker bottom sheet — drills down into subcategories, returns the
// selected leaf category.
// ---------------------------------------------------------------------------

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({required this.rootCategories});

  final List<Category> rootCategories;

  static Future<Category?> show(
    BuildContext context, {
    required List<Category> categories,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(rootCategories: categories),
    );
  }

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final List<Category> _stack = [];

  List<Category> get _currentLevel =>
      _stack.isEmpty ? widget.rootCategories : _stack.last.children;

  String get _title => _stack.isEmpty ? 'Выберите категорию' : _stack.last.name;

  void _open(Category category) {
    if (category.children.isNotEmpty) {
      setState(() => _stack.add(category));
    } else {
      Navigator.of(context).pop(category);
    }
  }

  void _back() => setState(() => _stack.removeLast());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
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
                if (_stack.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.arrow_back, color: textColor, size: 20),
                    onPressed: _back,
                  ),
                if (_stack.isNotEmpty) const SizedBox(width: 8),
                Text(
                  _title,
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
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _currentLevel.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              itemBuilder: (_, i) {
                final category = _currentLevel[i];
                final hasChildren = category.children.isNotEmpty;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  title: Text(
                    category.name,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                  trailing: hasChildren
                      ? Icon(Icons.chevron_right,
                          color: isDark ? Colors.white54 : Colors.black45)
                      : null,
                  onTap: () => _open(category),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }
}
