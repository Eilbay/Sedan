import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';

/// Result of the filter picker: the chosen category id, or null for "Все".
/// Wrapped in its own class so auto_route can disambiguate the return type.
class ReelCategoryPickResult {
  final String? categoryId;

  const ReelCategoryPickResult(this.categoryId);
}

/// Full-screen category picker for the reels feed. Single-select with an
/// "Все" entry at the top and an Apply button at the bottom. Pops with
/// [ReelCategoryPickResult]; caller applies the result to ReelBloc.
@RoutePage(name: 'ReelCategoryFilterRoute')
class ReelCategoryFilterScreen extends StatefulWidget {
  final String? initialCategoryId;

  const ReelCategoryFilterScreen({
    super.key,
    this.initialCategoryId,
  });

  @override
  State<ReelCategoryFilterScreen> createState() =>
      _ReelCategoryFilterScreenState();
}

class _ReelCategoryFilterScreenState extends State<ReelCategoryFilterScreen> {
  // null means "Все" is selected.
  String? _draftSelectedId;

  // Ids of categories that have at least one reel. Null while still probing.
  Set<String>? _categoriesWithReels;
  bool _hasStartedProbe = false;

  @override
  void initState() {
    super.initState();
    _draftSelectedId = widget.initialCategoryId;
  }

  void _apply() {
    // Return the user's choice to the caller. ReelBloc update happens there.
    context.router.maybePop(ReelCategoryPickResult(_draftSelectedId));
  }

  Future<void> _probeReelsPerCategory(List<Category> visibleCategories) async {
    if (_hasStartedProbe) return;
    _hasStartedProbe = true;

    final repo = getIt<IReelRepository>();
    final ids = visibleCategories.map((c) => c.id).toList();
    final probes = ids.map((id) => repo.hasReelsInCategory(id));
    final results = await Future.wait(probes);

    if (!mounted) return;
    setState(() {
      _categoriesWithReels = {
        for (var i = 0; i < ids.length; i++)
          if (results[i]) ids[i],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Фильтр по категориям'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<CategoryBloc, CategoryState>(
                buildWhen: (a, b) =>
                    a.categories != b.categories || a.isLoading != b.isLoading,
                builder: (ctx, state) {
                  if (state.isLoading && state.categories.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  // Drop internal technical categories — they have no
                  // user-facing meaning in the reels feed.
                  final visibleCategories = state.categories.where((c) {
                    final n = c.name.toLowerCase();
                    return !n.contains('статус') && !n.contains('склад');
                  }).toList();

                  // Kick off N parallel probes once categories are available.
                  if (!_hasStartedProbe && visibleCategories.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _probeReelsPerCategory(visibleCategories);
                    });
                  }

                  if (_categoriesWithReels == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final categories = visibleCategories
                      .where((c) => _categoriesWithReels!.contains(c.id))
                      .toList();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    // +1 for the synthetic "Все" row at the top.
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const Divider(
                      color: Colors.white12,
                      height: 1,
                      indent: 72,
                    ),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _CategoryTile(
                          title: 'Все',
                          iconUrl: null,
                          isSelected: _draftSelectedId == null,
                          onTap: () => setState(() => _draftSelectedId = null),
                        );
                      }
                      final c = categories[i - 1];
                      return _CategoryTile(
                        title: c.name,
                        iconUrl: c.icon.isEmpty ? null : c.icon,
                        isSelected: _draftSelectedId == c.id,
                        onTap: () => setState(() => _draftSelectedId = c.id),
                      );
                    },
                  );
                },
              ),
            ),
            _ApplyButton(onPressed: _apply),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String? iconUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.iconUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0095D5);
    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: accent.withValues(alpha: 0.08),
      leading: SizedBox(
        width: 40,
        height: 40,
        child: iconUrl == null
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apps, color: Colors.white70),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: iconUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(color: Colors.white10),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.category, color: Colors.white70),
                ),
              ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? accent : Colors.white,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: accent)
          : const Icon(Icons.radio_button_unchecked, color: Colors.white30),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ApplyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0095D5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Применить',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
