import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'package:optombai/bloc/language_bloc/language_event.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, Map<String, String>> _translationCache = {};
  final SharedPreferences preferences;

  LanguageBloc(this.preferences)
      : super(LanguageChangedState(
            preferences.getString('selected_language') ?? 'ru')) {
    on<ChangeLanguageEvent>(_onChangeLanguage);
    on<TranslateTextEvent>(_onTranslateText);
  }

  Future<void> _onChangeLanguage(
      ChangeLanguageEvent event, Emitter<LanguageState> emit) async {
    await preferences.setString('selected_language', event.language);
    emit(LanguageChangedState(event.language));
  }

  Future<void> _onTranslateText(
      TranslateTextEvent event, Emitter<LanguageState> emit) async {
    final currentLanguage = state is LanguageChangedState
        ? (state as LanguageChangedState).language
        : 'ru';

    final translatedText = await translateText(event.text, currentLanguage);
    emit(TranslationState(translatedText));
  }

  Future<String> translateText(String text, String language) async {
    if (language == 'ru') return text;

    if (_translationCache.containsKey(text) &&
        _translationCache[text]!.containsKey(language)) {
      return _translationCache[text]![language]!;
    }

    final translation =
        await _translator.translate(text, from: 'ru', to: language);

    _translationCache[text] ??= {};
    _translationCache[text]![language] = translation.text;

    return translation.text;
  }
}
