import 'package:equatable/equatable.dart';

abstract class LanguageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChangeLanguageEvent extends LanguageEvent {
  final String language;

  ChangeLanguageEvent(this.language);

  @override
  List<Object?> get props => [language];
}

class TranslateTextEvent extends LanguageEvent {
  final String text;

  TranslateTextEvent(this.text);

  @override
  List<Object?> get props => [text];
}
