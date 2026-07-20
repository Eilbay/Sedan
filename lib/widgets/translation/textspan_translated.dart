import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';

class TranslatedRichText extends StatefulWidget {
  final List<TranslatedTextSpanData> spans;
  final TextStyle? defaultStyle;

  const TranslatedRichText({
    super.key,
    required this.spans,
    this.defaultStyle,
  });

  @override
  State<TranslatedRichText> createState() => _TranslatedRichTextState();
}

class _TranslatedRichTextState extends State<TranslatedRichText> {
  List<String>? _translatedTexts;
  String? _lastLanguage;
  String? _lastTextsKey;
  int _requestVersion = 0;

  String _buildTextsKey(List<TranslatedTextSpanData> spans) {
    return spans.map((span) => span.text).join('\u0001');
  }

  void _translateIfNeeded(String language) {
    final textsKey = _buildTextsKey(widget.spans);
    if (_lastLanguage == language && _lastTextsKey == textsKey) return;

    _lastLanguage = language;
    _lastTextsKey = textsKey;
    _translatedTexts = null;
    final int requestVersion = ++_requestVersion;

    Future.wait(
      widget.spans.map(
        (span) =>
            context.read<LanguageBloc>().translateText(span.text, language),
      ),
    ).then((values) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() => _translatedTexts = values);
    }).catchError((_) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() =>
          _translatedTexts = widget.spans.map((span) => span.text).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.select<LanguageBloc, String>((bloc) {
      final state = bloc.state;
      return state is LanguageChangedState ? state.language : 'ru';
    });
    _translateIfNeeded(language);

    final children = <TextSpan>[];
    for (int i = 0; i < widget.spans.length; i++) {
      final span = widget.spans[i];
      final translatedText =
          (_translatedTexts != null && i < _translatedTexts!.length)
              ? _translatedTexts![i]
              : span.text;
      children.add(
        TextSpan(
          text: translatedText,
          style: span.style ?? widget.defaultStyle,
          recognizer: span.recognizer,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: widget.defaultStyle,
        children: children,
      ),
    );
  }
}

class TranslatedTextSpanData {
  final String text;
  final TextStyle? style;
  final GestureRecognizer? recognizer;

  TranslatedTextSpanData({
    required this.text,
    this.style,
    this.recognizer,
  });
}
