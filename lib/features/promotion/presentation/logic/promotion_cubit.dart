import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/features/promotion/data/models/create_campaign_request.dart';
import 'package:optombai/features/promotion/data/models/promotion_campaign_model.dart';
import 'package:optombai/features/promotion/data/models/promotion_package_model.dart';
import 'package:optombai/features/promotion/domain/repository/promotion_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'promotion_state.dart';

class PromotionCubit extends Cubit<PromotionState> {
  PromotionCubit(
      {required PromotionRepository repository, required this.preferences})
      : _repository = repository,
        super(const PromotionState());

  final SharedPreferences preferences;
  final PromotionRepository _repository;

  Future<bool> cancelActiveForPost(String postId) async {
    try {
      final active = await _repository.getActiveCampaignForPost(postId);
      if (active == null) return false;

      await _repository.cancelCampaign(active.id);

      if (state.currentPostId == postId) {
        emit(state.copyWith(activeCampaignForCurrentPost: null));
      }
      await loadMyCampaigns();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadForPost(
    String postId, {
    bool isAlreadyPromoted = false,
    DateTime? promoEndAt,
  }) async {
    emit(state.copyWith(
      status: PromotionStatus.loading,
      errorMessage: null,
      currentPostId: postId,
    ));

    try {
      final packages = await _repository.getPackages();
      final selectedPackage = packages.isNotEmpty ? packages.first : null;

      final activeCampaign = await _repository.getActiveCampaignForPost(postId);

      emit(state.copyWith(
        status: PromotionStatus.success,
        packages: packages,
        selectedPackage: selectedPackage,
        activeCampaignForCurrentPost: activeCampaign,
        errorMessage: null,
      ));
    } on AppException catch (e) {
      if (e.messages.any((m) => m.contains('Недостаточно средств'))) {
        emit(state.copyWith(
          status: PromotionStatus.insufficientBalance,
          errorMessage: e.messages.first,
        ));
        return;
      }

      emit(state.copyWith(
        status: PromotionStatus.error,
        errorMessage: e.messages.firstOrNull ?? 'Не удалось загрузить пакеты',
      ));
    } catch (e, st) {
      // Non-AppException here is almost always a model parsing error — log it
      // so it isn't silently masked as a generic message again.
      debugPrint('PromotionCubit.loadForPost failed: $e\n$st');
      emit(state.copyWith(
        status: PromotionStatus.error,
        errorMessage: 'Не удалось загрузить данные',
      ));
    }
  }

  void selectPackage(PromotionPackageModel package) {
    emit(state.copyWith(selectedPackage: package));
  }

  Future<bool> createCampaign(String postId) async {
    if (state.selectedPackage == null) return false;

    emit(state.copyWith(status: PromotionStatus.loading));

    try {
      final request = CreateCampaignRequest(
        postId: postId,
        packageId: state.selectedPackage!.id,
        days: state.selectedPackage!.days,
        idempotencyKey: _generateIdempotencyKey(postId),
      );

      final response = await _repository.createCampaign(request);
      await loadMyCampaigns();
      final real = state.myCampaigns.where((c) => c.postId == postId).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      final campaign = real.isNotEmpty ? real.first : null;

      emit(state.copyWith(
        status: PromotionStatus.success,
        activeCampaignForCurrentPost: campaign,
        lastResponse: response,
      ));

      return true;
    } on AppException catch (e) {
      if (e.messages.any((m) => m.contains('Недостаточно средств'))) {
        emit(state.copyWith(
          status: PromotionStatus.insufficientBalance,
          errorMessage: e.messages.first,
        ));
        return false;
      }

      emit(state.copyWith(
        status: PromotionStatus.error,
        errorMessage: e.messages.firstOrNull ?? 'Ошибка создания кампании',
      ));
      return false;
    } catch (e, st) {
      debugPrint('PromotionCubit.createCampaign failed: $e\n$st');
      emit(state.copyWith(
        status: PromotionStatus.error,
        errorMessage: 'Ошибка создания кампании',
      ));
      return false;
    }
  }

  Future<void> loadMyCampaigns() async {
    try {
      final campaigns = await _repository.getMyCampaigns();
      emit(state.copyWith(myCampaigns: campaigns));
    } catch (e, st) {
      debugPrint('PromotionCubit.loadMyCampaigns failed: $e\n$st');
    }
  }

  void reset() {
    emit(const PromotionState());
  }

  String _generateIdempotencyKey(String postId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${postId}_${timestamp}_$random';
  }
}
