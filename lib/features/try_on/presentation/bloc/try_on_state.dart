import 'package:equatable/equatable.dart';
import 'package:optombai/features/try_on/domain/entities/%20model_validation.dart';
import 'package:optombai/features/try_on/domain/entities/%20try_on_task.dart';

import 'package:optombai/features/try_on/domain/entities/clothes_validation.dart';

class TryOnState extends Equatable {
  final bool loading;
  final String? error;
  final int? generationsLeft;
  final String? clothType;
  final ClothesValidation? clothesValidation;
  final ModelValidation? modelValidation;
  final TryOnTask? task;
  final Uri? resultUrl;

  const TryOnState({
    this.loading = false,
    this.error,
    this.generationsLeft,
    this.clothType,
    this.clothesValidation,
    this.modelValidation,
    this.task,
    this.resultUrl,
  });

  TryOnState copyWith({
    bool? loading,
    String? error,
    int? generationsLeft,
    String? clothType,
    ClothesValidation? clothesValidation,
    ModelValidation? modelValidation,
    TryOnTask? task,
    Uri? resultUrl,
  }) =>
      TryOnState(
        loading: loading ?? this.loading,
        error: error,
        generationsLeft: generationsLeft ?? this.generationsLeft,
        clothType: clothType ?? this.clothType,
        clothesValidation: clothesValidation ?? this.clothesValidation,
        modelValidation: modelValidation ?? this.modelValidation,
        task: task ?? this.task,
        resultUrl: resultUrl ?? this.resultUrl,
      );

  @override
  List<Object?> get props => [
        loading,
        error,
        generationsLeft,
        clothType,
        clothesValidation,
        modelValidation,
        task,
        resultUrl
      ];
}
