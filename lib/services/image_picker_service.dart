import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

/// Handles picking and saving images from camera/gallery.
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the given source and saves it permanently.
  Future<File?> pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image == null) return null;

    return _savePermanently(image.path);
  }

  /// Lets the user preview and crop the picked image to a square before
  /// upload, so they see exactly how the avatar will look.
  Future<File?> cropImage(File image) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Обрезать фото',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          // Dark toolbar -> keep white (non-"light") status bar icons.
          statusBarLight: false,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Обрезать фото',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null) return null;

    return File(cropped.path);
  }

  Future<File> _savePermanently(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = basename(imagePath);
    final destination = File('${directory.path}/$name');

    return File(imagePath).copy(destination.path);
  }
}
