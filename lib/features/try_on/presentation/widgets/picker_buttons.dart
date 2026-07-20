import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickerButtons extends StatelessWidget {
  final File? modelImage;
  final File? clothImage;
  final File? lowerClothImage;

  final ValueChanged<File> onModelPicked;
  final ValueChanged<File> onClothPicked;
  final ValueChanged<File>? onLowerClothPicked;

  const PickerButtons({
    super.key,
    required this.onModelPicked,
    required this.onClothPicked,
    this.onLowerClothPicked,
    this.modelImage,
    this.clothImage,
    this.lowerClothImage,
  });

  Future<void> _pick(BuildContext context, ValueChanged<File> onPicked) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
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
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? x = await picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 2048,
    );

    if (x != null) {
      onPicked(File(x.path));
    }
  }

  Widget _thumb(File? file, String placeholder) {
    if (file == null) {
      return Container(
        height: 120,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: Text(placeholder, style: const TextStyle(color: Colors.grey)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(file,
          height: 160, width: double.infinity, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Фото модели', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _thumb(modelImage, 'Фото модели не выбрано'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _pick(context, onModelPicked),
          icon: const Icon(Icons.person),
          label: const Text('Выбрать модель'),
        ),
        const SizedBox(height: 16),
        Text('Фото одежды (верх или единичная вещь)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _thumb(clothImage, 'Фото одежды не выбрано'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _pick(context, onClothPicked),
          icon: const Icon(Icons.checkroom),
          label: const Text('Выбрать одежду'),
        ),
        if (onLowerClothPicked != null) ...[
          const SizedBox(height: 16),
          Text('Фото низа (для комплекта)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _thumb(lowerClothImage, 'Фото низа не выбрано'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pick(context, onLowerClothPicked!),
            icon: const Icon(Icons.checkroom_outlined),
            label: const Text('Выбрать низ'),
          ),
        ],
      ],
    );
  }
}
