import 'dart:io';
import 'package:dio/dio.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/features/try_on/domain/entities/%20model_validation.dart';
import 'package:optombai/features/try_on/domain/entities/%20try_on_task.dart';

import 'package:optombai/features/try_on/domain/entities/clothes_validation.dart';
import 'package:optombai/features/try_on/domain/repositories/try_on_repository.dart';

class TryOnRepositoryImpl implements TryOnRepository {
  late final Dio _dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseApi));

  static const String _fitAi = 'fit-ai';
  static const String _validateClothes = '/$_fitAi/validate/clothes/';
  static const String _validateModel = '/$_fitAi/validate/model/';
  static const String _taskCreate = '/$_fitAi/task/create/';
  static String _taskStatus(String id) => '/$_fitAi/tasks/$id/status/';
  static const String _models = '/models';
  static String get _subscription => '${ApiEndpoints.accountsApi}/subscription/';

  @override
  Future<ClothesValidation> validateClothes(File image, String token) async {
    final fd = FormData.fromMap({
      'input_image': await MultipartFile.fromFile(image.path,
          filename: image.uri.pathSegments.last),
    });
    final res = await _dio.post(_validateClothes,
        data: fd, options: optionsFormData(token));
    return ClothesValidation.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ModelValidation> validateModel(File image, String token) async {
    final fd = FormData.fromMap({
      'input_image': await MultipartFile.fromFile(image.path,
          filename: image.uri.pathSegments.last),
    });
    final res = await _dio.post(_validateModel,
        data: fd, options: optionsFormData(token));
    return ModelValidation.fromJson(res.data as Map<String, dynamic>);
  }

  String _normalizeClothType(String? t) {
    final v = (t ?? '').trim().toLowerCase();
    if (v == 'top' || v == 'bottom' || v == 'fullset' || v == 'fullest') {
      return v;
    }
    if (v == 'full') return 'fullset';
    return 'fullset';
  }

  @override
  Future<TryOnTask> createTask({
    required File modelImage,
    required File clothImage,
    required String clothType,
    File? lowerClothImage,
    required String token,
  }) async {
    try {
      final normalizedType = _normalizeClothType(clothType);

      debugPrint(
          '[fit-ai] createTask → cloth_type(raw)="$clothType" -> (norm)="$normalizedType"');

      final map = <String, dynamic>{
        'model_image': await MultipartFile.fromFile(
          modelImage.path,
          filename: modelImage.uri.pathSegments.last,
        ),
        'cloth_image': await MultipartFile.fromFile(
          clothImage.path,
          filename: clothImage.uri.pathSegments.last,
        ),
        'cloth_type': normalizedType,
      };

      if (lowerClothImage != null) {
        final liLen = await lowerClothImage.length();
        debugPrint(
            '[fit-ai] lower_cloth_image: ${lowerClothImage.path} (${liLen}b)');
        map['lower_cloth_image'] = await MultipartFile.fromFile(
          lowerClothImage.path,
          filename: lowerClothImage.uri.pathSegments.last,
        );
      }

      final form = FormData.fromMap(map);

      final res = await _dio.post(
        _taskCreate,
        data: form,
        options: optionsFormData(token).copyWith(
          validateStatus: (code) => true,
        ),
      );

      if (res.statusCode == null ||
          res.statusCode! < 200 ||
          res.statusCode! >= 300) {
        debugPrint('[fit-ai] createTask FAILED '
            'code=${res.statusCode}, data=${res.data}, headers=${res.headers}');
        throw Exception(_serverErrorMessage(
          'Create task failed',
          res.statusCode,
          res.data,
        ));
      }

      debugPrint(
          '[fit-ai] createTask OK code=${res.statusCode} data=${res.data}');
      return TryOnTask.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e, st) {
      debugPrint('[fit-ai] DioException on createTask '
          'code=${e.response?.statusCode} msg=${e.message}\n'
          'data=${e.response?.data}\nheaders=${e.response?.headers}\n$st');

      final msg = _serverErrorMessage(
          'Create task failed', e.response?.statusCode, e.response?.data);
      throw Exception(msg);
    } catch (e, st) {
      debugPrint('[fit-ai] Unexpected error on createTask: $e\n$st');
      rethrow;
    }
  }

  String _serverErrorMessage(String prefix, int? code, dynamic data) {
    final err = (data is Map && data['error'] != null)
        ? data['error'].toString()
        : data?.toString();
    return '$prefix (HTTP ${code ?? '?'})${err != null ? ': $err' : ''}';
  }

  @override
  Future<TryOnTask> getTaskStatus(String taskId, String token) async {
    final res = await _dio.get(_taskStatus(taskId), options: options(token));
    return TryOnTask.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<Map<String, dynamic>>> getModels(
      {String? nationality, String? type, String? age, String? token}) async {
    final res = await _dio.get(
      _models,
      queryParameters: {
        if (nationality != null) 'nationality': nationality,
        if (type != null) 'type': type,
        if (age != null) 'age': age,
      },
      options: token != null ? options(token) : null,
    );
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> getSubscription(String token) async {
    final res = await _dio.get(_subscription, options: options(token));
    return (res.data as Map<String, dynamic>);
  }
}
