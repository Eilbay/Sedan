import 'dart:io';
import 'package:optombai/features/try_on/domain/entities/%20model_validation.dart';
import 'package:optombai/features/try_on/domain/entities/%20try_on_task.dart';

import 'package:optombai/features/try_on/domain/entities/clothes_validation.dart';

abstract class TryOnRepository {
  Future<ClothesValidation> validateClothes(File image, String token);
  Future<ModelValidation> validateModel(File image, String token);

  Future<TryOnTask> createTask({
    required File modelImage,
    required File clothImage,
    required String clothType,
    File? lowerClothImage,
    required String token,
  });

  Future<TryOnTask> getTaskStatus(String taskId, String token);
  Future<List<Map<String, dynamic>>> getModels(
      {String? nationality, String? type, String? age, String? token});
  Future<Map<String, dynamic>> getSubscription(String token);
}
