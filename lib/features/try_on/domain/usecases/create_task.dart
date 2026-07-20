import 'dart:io';
import 'package:optombai/features/try_on/domain/entities/%20try_on_task.dart';

import 'package:optombai/features/try_on/domain/repositories/try_on_repository.dart';

class CreateTask {
  final TryOnRepository repo;
  CreateTask(this.repo);

  Future<TryOnTask> call({
    required File modelImage,
    required File clothImage,
    required String clothType,
    File? lowerClothImage,
    required String token,
  }) =>
      repo.createTask(
        modelImage: modelImage,
        clothImage: clothImage,
        clothType: clothType,
        lowerClothImage: lowerClothImage,
        token: token,
      );
}
