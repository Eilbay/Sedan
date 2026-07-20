import 'dart:io';
import 'package:optombai/features/try_on/domain/entities/%20model_validation.dart';

import 'package:optombai/features/try_on/domain/repositories/try_on_repository.dart';

class ValidateModel {
  final TryOnRepository repo;
  ValidateModel(this.repo);
  Future<ModelValidation> call(File img, String token) =>
      repo.validateModel(img, token);
}
