import 'dart:io';
import 'package:optombai/features/try_on/domain/entities/clothes_validation.dart';
import 'package:optombai/features/try_on/domain/repositories/try_on_repository.dart';

class ValidateClothes {
  final TryOnRepository repo;
  ValidateClothes(this.repo);
  Future<ClothesValidation> call(File img, String token) =>
      repo.validateClothes(img, token);
}
