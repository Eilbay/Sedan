import 'dart:io';

import 'package:optombai/data/models/image/image_model.dart';

abstract interface class IImageRepository {
  Future<void> createOrgPhoto(String token, File image, String userId);

  Future<void> deleteOrgPhoto(int id, String token);

  Future<List<ImageAboutModel>> getOrgPhotos(String userId, String token);

  Future<void> createDocument(String token, File image, String userId);

  Future<void> deleteDocument(int id, String token);

  Future<List<DocumentImageModel>> getDocuments(String userId, String token);
}
