import 'package:bloc/bloc.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/repositories/i_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:optombai/bloc/country_bloc/country_event.dart';
import 'package:optombai/bloc/country_bloc/country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final ISettingsRepository _repository;
  final SharedPreferences preferences;

  CountryBloc({required ISettingsRepository repository, required this.preferences})
      : _repository = repository,
        super(const CountryState()) {
    on<CountryAllEvent>(countryAll);
  }

  countryAll(CountryAllEvent event, emit) async {
    if (!event.forceRefresh && state.list.isNotEmpty) return;

    emit(state.copyWith(isLoading: true));
    try {
      var list = await _repository.getCountry();
      emit(state.copyWith(list: list));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }
}
