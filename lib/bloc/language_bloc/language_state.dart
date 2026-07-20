import 'package:equatable/equatable.dart';

abstract class LanguageState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LanguageInitialState extends LanguageState {}

class LanguageChangedState extends LanguageState {
  final String language;

  LanguageChangedState(this.language);

  @override
  List<Object?> get props => [language];
}

class TranslationState extends LanguageState {
  final String translatedText;

  TranslationState(this.translatedText);

  @override
  List<Object?> get props => [translatedText];
}

class LanguageLoadedState extends LanguageState {
  final String language;
  final Map<String, String> translations;

  LanguageLoadedState({
    required this.language,
    required this.translations,
  });
}
