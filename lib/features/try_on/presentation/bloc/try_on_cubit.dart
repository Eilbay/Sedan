import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/features/try_on/domain/repositories/try_on_repository.dart';
import 'package:optombai/features/try_on/presentation/bloc/try_on_state.dart';
import 'package:optombai/features/try_on/domain/entities/task_status.dart';
import 'package:optombai/features/try_on/domain/usecases/validate_model.dart';
import 'package:optombai/features/try_on/domain/usecases/validate_clothes.dart';
import 'package:optombai/features/try_on/domain/usecases/create_task.dart';
import 'package:optombai/features/try_on/domain/usecases/get_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/configs/constrants.dart';

class TryOnCubit extends Cubit<TryOnState> {
  final TryOnRepository repo;
  final ValidateClothes validateClothesUC;
  final ValidateModel validateModelUC;
  final CreateTask createTaskUC;
  final GetStatus getStatusUC;
  final SharedPreferences prefs;

  TryOnCubit({
    required this.repo,
    required this.validateClothesUC,
    required this.validateModelUC,
    required this.createTaskUC,
    required this.getStatusUC,
    required this.prefs,
  }) : super(const TryOnState());

  String get _token => prefs.getString(TOKEN_KEY) ?? "";

  Timer? _poll;

  Future<void> loadSubscription() async {
    final s = await repo.getSubscription(_token);
    emit(state.copyWith(generationsLeft: s['generations_left'] as int?));
  }

  Future<void> onPickClothes(File f) async {
    final v = await validateClothesUC(f, _token);
    emit(state.copyWith(clothesValidation: v, clothType: v.clothesType));
  }

  Future<void> onPickModel(File f) async {
    final v = await validateModelUC(f, _token);
    emit(state.copyWith(modelValidation: v));
  }

  Future<void> startGenerate({
    required File modelImage,
    required File clothImage,
    String? clothTypeOverride,
  }) async {
    final effectiveType = clothTypeOverride ?? state.clothType ?? 'fullset';

    emit(state.copyWith(loading: true, error: null, resultUrl: null));
    final task = await createTaskUC(
      modelImage: modelImage,
      clothImage: clothImage,
      clothType: effectiveType,
      token: _token,
    );
    emit(state.copyWith(task: task));

    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      final s = await getStatusUC(task.taskId, _token);
      emit(state.copyWith(
        task: s,
        loading: s.status != TryOnTaskStatus.completed &&
            s.status != TryOnTaskStatus.failed,
      ));
      if (s.status == TryOnTaskStatus.completed ||
          s.status == TryOnTaskStatus.failed) {
        _poll?.cancel();
        emit(state.copyWith(resultUrl: s.downloadUrl));
      }
    });
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
