import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus2/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class TryOnResultPage extends StatefulWidget {
  final String imageUrl;
  const TryOnResultPage({super.key, required this.imageUrl});

  @override
  State<TryOnResultPage> createState() => _TryOnResultPageState();
}

class _TryOnResultPageState extends State<TryOnResultPage> {
  bool _saving = false;

  Future<void> _save() async {
    try {
      setState(() => _saving = true);

      final status = await Permission.photos.request();
      if (!status.isGranted && Platform.isAndroid) {
        final st2 = await Permission.storage.request();
        if (!st2.isGranted) {
          throw Exception('Нет доступа к хранилищу');
        }
      }

      final tmpDir = await getTemporaryDirectory();
      final path =
          '${tmpDir.path}/fitroom_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final resp = await Dio().get<List<int>>(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final file = File(path);
      await file.writeAsBytes(resp.data!);

      final res = await ImageGallerySaverPlus.saveFile(file.path);
      if (!mounted) return;

      final ok =
          (res is Map && (res['isSuccess'] == true || res['filePath'] != null));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok ? 'Сохранено в галерею' : 'Не удалось сохранить')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Результат')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: widget.imageUrl, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.error)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                label: Text(_saving ? 'Сохраняем…' : 'Скачать'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
