import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optombai/app/router/app_router.dart';

import 'package:optombai/features/try_on/presentation/bloc/try_on_cubit.dart';
import 'package:optombai/features/try_on/presentation/bloc/try_on_state.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class TryOnPage extends StatefulWidget {
  const TryOnPage({super.key});

  @override
  State<TryOnPage> createState() => _TryOnPageState();
}

class _TryOnPageState extends State<TryOnPage> {
  final _picker = ImagePicker();

  File? _clothImage;
  File? _modelImage;

  int _clothMode = 0;
  String? _manualClothType;
  int _modelsTab = 0;
  bool _hd = false;

  Future<File?> _pick(ImageSource source) async {
    final x = await _picker.pickImage(source: source, imageQuality: 95);
    if (x == null) return null;
    final f = File(x.path);
    final bytes = await f.length();
    if (bytes > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл больше 10 МБ. Выберите другой.')),
        );
      }
      return null;
    }
    return f;
  }

  Future<void> _pickClothes() async {
    final src = await _chooseSource();
    if (src == null) return;
    final f = await _pick(src);
    if (f == null) return;
    if (!mounted) return;
    setState(() => _clothImage = f);
    await context.read<TryOnCubit>().onPickClothes(f);
  }

  Future<void> _pickModel() async {
    final src = await _chooseSource();
    if (src == null) return;
    final f = await _pick(src);
    if (f == null) return;
    if (!mounted) return;
    setState(() => _modelImage = f);
    await context.read<TryOnCubit>().onPickModel(f);
  }

  Future<ImageSource?> _chooseSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Галерея'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Камера'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TryOnCubit, TryOnState>(
      listener: (ctx, s) {
        if (s.error != null) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(SnackBar(content: Text(s.error!)));
        }
      },
      builder: (ctx, s) {
        const hasAiAccess = true;
        final canGenerate = hasAiAccess &&
            _clothImage != null &&
            _modelImage != null &&
            !s.loading;

        final detectedType = s.clothType;
        final effectiveType = _manualClothType ?? detectedType ?? 'fullset';

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.checkroom_outlined),
                SizedBox(width: 8),
                Text('ИИ‑примерка'),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GenerationsBar(
                  generationsLeft: s.generationsLeft,
                  onRefresh: () =>
                      context.read<TryOnCubit>().loadSubscription(),
                ),
                const SizedBox(height: 16),
                const _SectionTitle(text: 'Выбрать одежду'),
                const SizedBox(height: 8),
                _Segmented(
                  segments: const ['Одиночная одежда', 'Верх & низ'],
                  selectedIndex: _clothMode,
                  onChanged: (i) => setState(() => _clothMode = i),
                ),
                const SizedBox(height: 12),
                _UploadArea(
                  child: _ClothUploadContent(
                    effectiveType: effectiveType,
                    clothImage: _clothImage,
                    onPickClothes: _pickClothes,
                    onClearClothes: () =>
                        setState(() => _clothImage = null),
                  ),
                ),
                const SizedBox(height: 16),
                const _SubTitleRow(text: 'Недавние элементы', action: 'Посмотреть все'),
                const SizedBox(height: 8),
                const _RecentStrip(),
                const SizedBox(height: 20),
                const _SectionTitle(text: 'Выбрать модель'),
                const SizedBox(height: 4),
                const _ModelInfoHint(),
                const SizedBox(height: 12),
                _TabPills(
                  tabs: const ['Наши модели', 'Ваши модели'],
                  index: _modelsTab,
                  onChanged: (i) => setState(() => _modelsTab = i),
                ),
                const SizedBox(height: 12),
                _ModelsGrid(
                  myTab: _modelsTab,
                  onUploadTap: _pickModel,
                  preview: _modelImage,
                  onPickPreset: (imgFile) {
                    setState(() => _modelImage = imgFile);
                  },
                ),
                const SizedBox(height: 12),
                _HdToggleRow(
                  hd: _hd,
                  onChanged: (v) => setState(() => _hd = v),
                ),
                const SizedBox(height: 8),
                _CreateButton(
                  enabled: canGenerate,
                  trailingBadge: 'Быстро – 1 кредитов',
                  onPressed: () {
                    final selectedType =
                        _manualClothType ?? s.clothType ?? 'fullset';

                    context.read<TryOnCubit>().startGenerate(
                        modelImage: _modelImage!,
                        clothImage: _clothImage!,
                        clothTypeOverride: selectedType);

                    context.router.push(const TryOnProgressRoute());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _SubTitleRow extends StatelessWidget {
  final String text;
  final String? action;

  const _SubTitleRow({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
      ],
    );
  }
}

class _GenerationsBar extends StatelessWidget {
  final int? generationsLeft;
  final VoidCallback onRefresh;

  const _GenerationsBar({
    required this.generationsLeft,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 20),
        const SizedBox(width: 8),
        const Text('Осталось генераций'),
        const Spacer(),
        Chip(label: Text('$generationsLeft')),
        IconButton(
          tooltip: 'Обновить',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _ClothUploadContent extends StatelessWidget {
  final String effectiveType;
  final File? clothImage;
  final VoidCallback onPickClothes;
  final VoidCallback onClearClothes;

  const _ClothUploadContent({
    required this.effectiveType,
    required this.clothImage,
    required this.onPickClothes,
    required this.onClearClothes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _DropdownPill(label: 'Обычный крой'),
              _DropdownPill(
                label: effectiveType == 'top'
                    ? 'Верх'
                    : effectiveType == 'bottom'
                        ? 'Низ'
                        : 'Платье/Костюм',
              ),
              IconButton(
                onPressed: onPickClothes,
                icon: const Icon(Icons.file_upload_outlined),
                tooltip: 'Загрузить',
              ),
              IconButton(
                onPressed: onClearClothes,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Удалить',
              ),
            ],
          ),
        ),
        if (clothImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              clothImage!,
              height: 86,
              width: 64,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }
}

class _ModelInfoHint extends StatelessWidget {
  const _ModelInfoHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.info_outline, size: 18),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Выберите нашу модель или загрузите свою для примерки',
          ),
        ),
      ],
    );
  }
}

class _HdToggleRow extends StatelessWidget {
  final bool hd;
  final ValueChanged<bool> onChanged;

  const _HdToggleRow({
    required this.hd,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Switch(
            value: hd,
            onChanged: onChanged,
          ),
          const SizedBox(width: 6),
          const Text('Режим высокого качества'),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('HD', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _Segmented({
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(segments.length, (i) {
        final selected = i == selectedIndex;
        return ChoiceChip(
          label: Text(segments[i]),
          selected: selected,
          onSelected: (_) => onChanged(i),
        );
      }),
    );
  }
}

class _UploadArea extends StatelessWidget {
  final Widget child;
  const _UploadArea({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _DropdownPill extends StatelessWidget {
  final String label;
  const _DropdownPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down, size: 18),
      ]),
    );
  }
}

class _RecentStrip extends StatelessWidget {
  const _RecentStrip();

  @override
  Widget build(BuildContext context) {
    final items = List.generate(7, (i) => i);
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 64,
                width: 50,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 20, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Демо',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPills extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  const _TabPills(
      {required this.tabs, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = i == index;
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: i == 0 ? 8 : 0, left: i == 1 ? 8 : 0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                foregroundColor: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
              onPressed: () => onChanged(i),
              child: Text(tabs[i]),
            ),
          ),
        );
      }),
    );
  }
}

class _ModelsGrid extends StatelessWidget {
  final int myTab;
  final VoidCallback onUploadTap;
  final File? preview;
  final ValueChanged<File> onPickPreset;

  const _ModelsGrid({
    required this.myTab,
    required this.onUploadTap,
    required this.preview,
    required this.onPickPreset,
  });

  @override
  Widget build(BuildContext context) {
    if (myTab == 1) {
      return Row(
        children: [
          _UploadTile(onTap: onUploadTap),
          const SizedBox(width: 12),
          Expanded(
            child: preview == null
                ? _stub()
                : _thumb(Image.file(preview!, fit: BoxFit.cover)),
          ),
        ],
      );
    }

    final placeholders = List.generate(6, (_) => _stub());
    return GridView.builder(
      itemCount: placeholders.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .75,
      ),
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () async {},
        child: placeholders[i],
      ),
    );
  }

  Widget _stub() => _thumb(Container(color: Colors.grey.shade200));
  Widget _thumb(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(aspectRatio: 3 / 4, child: child),
      );
}

class _UploadTile extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 150,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28),
            SizedBox(height: 6),
            Text('Загрузить'),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final bool enabled;
  final String trailingBadge;
  final VoidCallback onPressed;
  const _CreateButton({
    required this.enabled,
    required this.trailingBadge,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: enabled ? onPressed : null,
      child: const Text('Создать', style: TextStyle(fontSize: 18)),
    );

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        btn,
        Positioned(
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailingBadge,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
