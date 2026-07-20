import 'package:bloc/bloc.dart';
import 'package:optombai/data/models/currency/currency_model.dart';
import 'package:optombai/data/repositories/i_settings_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/configs/constrants.dart';

part 'currency_event.dart';

part 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final ISettingsRepository _repository;
  final SharedPreferences preferences;

  CurrencyBloc({required ISettingsRepository repository, required this.preferences})
      : _repository = repository,
        super(const CurrencyState()) {
    on<CurrencyAllEvent>(_getAllCurrency);
    on<SetSelectedCurrencyEvent>(_setCurrency);
  }
  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  Future<void> _getAllCurrency(CurrencyAllEvent event, Emitter emit) async {
    if (!event.forceRefresh && state.currency.isNotEmpty) return;

    final token = getToken();
    if (token.isEmpty) return;

    emit(state.copyWith(isLoading: true));
    try {
      final list = await _repository.getCurrency(token);
      final prefs = preferences;
      final saved = prefs.getString("currency_code");
      final selected = list.firstWhere(
        (e) => e.name == saved,
        orElse: () => list.first,
      );
      emit(state.copyWith(
          isSuccess: true, currency: list, selectedCurrency: selected));
    } catch (e) {
      emit(state.copyWith(errors: ["Ошибка загрузки валют"]));
    }
  }

  Future<void> _setCurrency(
      SetSelectedCurrencyEvent event, Emitter emit) async {
    await preferences.setString("currency_code", event.selected.name);
    emit(state.copyWith(selectedCurrency: event.selected));
  }
}
