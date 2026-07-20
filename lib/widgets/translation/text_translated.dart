import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';

class TextTranslated extends StatefulWidget {
  final String keyText;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextAlign? textAlign;

  const TextTranslated(
    this.keyText, {
    this.style,
    this.maxLines,
    this.softWrap,
    this.textAlign,
    this.overflow,
    super.key,
  });

  @override
  State<TextTranslated> createState() => _TextTranslatedState();
}

class _TextTranslatedState extends State<TextTranslated> {
  String? _translated;
  String? _lastLanguage;
  String? _lastKeyText;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _translated = widget.keyText;
  }

  void _translateIfNeeded(String language) {
    if (_lastLanguage == language && _lastKeyText == widget.keyText) return;

    _lastLanguage = language;
    _lastKeyText = widget.keyText;
    _translated = widget.keyText;
    final int requestVersion = ++_requestVersion;

    context
        .read<LanguageBloc>()
        .translateText(widget.keyText, language)
        .then((value) {
      if (!mounted || requestVersion != _requestVersion) return;
      if (value == _translated) return;
      setState(() => _translated = value);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final language = context.select<LanguageBloc, String>((bloc) {
      final state = bloc.state;
      return state is LanguageChangedState ? state.language : 'ru';
    });

    _translateIfNeeded(language);

    return Text(
      _translated ?? widget.keyText,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap,
      textAlign: widget.textAlign,
    );
  }
}
