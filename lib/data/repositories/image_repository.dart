import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/image/image_model.dart';
import 'package:optombai/data/repositories/i_image_repository.dart';

String get _endpointOrgPhotos => '${ApiEndpoints.accountsApi}/user_content/';
String get _endpointDocuments => '${ApiEndpoints.accountsApi}/documents/';

class ImageRepository implements IImageRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<File> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.parent.path}/compressed_${file.uri.pathSegments.last}',
      quality: 80,
      minWidth: 1920,
      minHeight: 1920,
    );
    return result != null ? File(result.path) : file;
  }

  Future<void> createOrgPhoto(String token, File image, String userId) async {
    try {
      final compressed = await _compressImage(image);
      final form = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          compressed.path,
          filename: compressed.path.split('/').last,
        ),
        "user": userId,
      });

      await _dio.post(
        _endpointOrgPhotos,
        data: form,
        options: optionsFormData(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteOrgPhoto(int id, String token) async {
    try {
      await _dio.delete('$_endpointOrgPhotos$id/', options: options(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<ImageAboutModel>> getOrgPhotos(
      String userId, String token) async {
    try {
      final res = await _dio.get(
        _endpointOrgPhotos,
        queryParameters: {'user': userId},
        options: options(token),
      );

      final list = (res.data["results"] as List)
          .map((item) => ImageAboutModel.fromJson(item))
          .toList();

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> createDocument(String token, File image, String userId) async {
    try {
      final compressed = await _compressImage(image);
      final form = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          compressed.path,
          filename: compressed.path.split('/').last,
        ),
        "user": userId,
      });

      await _dio.post(
        _endpointDocuments,
        data: form,
        options: optionsFormData(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteDocument(int id, String token) async {
    try {
      await _dio.delete('$_endpointDocuments$id/', options: options(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<DocumentImageModel>> getDocuments(
      String userId, String token) async {
    try {
      final res = await _dio.get(
        _endpointDocuments,
        queryParameters: {'user': userId},
        options: options(token),
      );

      final list = (res.data["results"] as List)
          .map((item) => DocumentImageModel.fromJson(item))
          .toList();

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
