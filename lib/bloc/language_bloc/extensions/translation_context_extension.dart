import 'package:optombai/bloc/language_bloc/language_state.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/bloc/language_bloc/language_bloc.dart';

extension TranslationContextExtension on BuildContext {
  Future<String> translateText(String text) async {
    final languageBloc = read<LanguageBloc>();
    final state = languageBloc.state;
    final selectedLanguage =
        state is LanguageChangedState ? state.language : 'ru';
    return languageBloc.translateText(text, selectedLanguage);
  }
}
