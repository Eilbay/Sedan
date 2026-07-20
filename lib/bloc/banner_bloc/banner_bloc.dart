import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/data/models/banner/settings_banners_model.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:optombai/configs/constrants.dart';
import 'package:optombai/data/repositories/i_settings_repository.dart';

part 'banner_event.dart';

part 'banner_state.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final ISettingsRepository _repository;
  final SharedPreferences preferences;

  BannerBloc({required ISettingsRepository repository, required this.preferences})
      : _repository = repository,
        super(BannerInitial()) {
    on<BannerAllEvent>(getAllBanner);
  }
  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  getAllBanner(BannerAllEvent event, emit) async {
    if (!event.forceRefresh && state is BannerSuccess) {
      debugPrint('[PRELOAD] Banners SKIP (cached)');
      return;
    }

    debugPrint('[PRELOAD] Banners FETCHING');
    final sw = Stopwatch()..start();
    emit(BannerLoading());
    try {
      var list = await _repository.getBanner();
      debugPrint('[PRELOAD] Banners DONE ${sw.elapsedMilliseconds}ms — ${list.length} banners');
      emit(BannerSuccess(list));
    } catch (e) {
      debugPrint('[PRELOAD] Banners ERROR ${sw.elapsedMilliseconds}ms — $e');
      emit(BannerError());
    }
  }
}
