import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/core/theme_notifier.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.title,
    this.icon,
    this.isEmail = false,
    required this.onChanged,
    this.controller,
    this.textInputType,
    this.textInputAction,
    this.onPressed,
    this.obscureText = false,
    this.maxLines,
    this.initValue,
    this.errorText,
    this.path,
    this.isPassword,
    this.isName = false,
    this.isDesc = false,
    this.isNumber = false,
    this.isAuthName = false,
    this.inputFormatters = 100,
    this.isError = false,
    this.filledOverride,
    this.fillColorLight,
    this.fillColorDark,
    this.fixedPlus = false,
    this.hideHintOnFocus = true,
    this.focusNode,
    this.minLines,
  });

  final String? title;
  final IconData? icon;
  final Function onChanged;
  final TextEditingController? controller;
  final TextInputType? textInputType;
  final TextInputAction? textInputAction;
  final VoidCallback? onPressed;
  final bool? obscureText;
  final Widget? path;
  final int? maxLines;
  final int? inputFormatters;
  final String? errorText;
  final String? initValue;
  final bool? isPassword;
  final bool? isEmail;
  final bool? isAuthName;
  final bool? isDesc;
  final bool? isNumber;
  final bool? isName;
  final bool? isError;
  final bool? filledOverride;
  final Color? fillColorLight;
  final Color? fillColorDark;
  final int? minLines;

  final bool fixedPlus;

  final bool hideHintOnFocus;
  final FocusNode? focusNode;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _hasFocus = false;

  String _translatedTitle = '';
  String _translatedErrorText = '';
  String? _lastLanguage;
  String? _lastTitleKey;
  String? _lastErrorKey;
  int _translationVersion = 0;

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();

    _translatedTitle = widget.title ?? '';
    _translatedErrorText = widget.errorText ?? '';

    _hasFocus = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  bool get _isEmpty =>
      (widget.controller?.text ?? widget.initValue ?? '').isEmpty;

  void _translateIfNeeded(String language) {
    final titleKey = widget.title ?? '';
    final errorKey = widget.errorText ?? '';

    if (_lastLanguage == language &&
        _lastTitleKey == titleKey &&
        _lastErrorKey == errorKey) {
      return;
    }

    _lastLanguage = language;
    _lastTitleKey = titleKey;
    _lastErrorKey = errorKey;

    _translatedTitle = titleKey;
    _translatedErrorText = errorKey;

    if (titleKey.isEmpty && errorKey.isEmpty) return;

    final requestVersion = ++_translationVersion;
    Future.wait([
      context.read<LanguageBloc>().translateText(titleKey, language),
      context.read<LanguageBloc>().translateText(errorKey, language),
    ]).then((values) {
      if (!mounted || requestVersion != _translationVersion) return;
      setState(() {
        _translatedTitle = values[0];
        _translatedErrorText = values[1];
      });
    }).catchError((_) {
      if (!mounted || requestVersion != _translationVersion) return;
      setState(() {
        _translatedTitle = titleKey;
        _translatedErrorText = errorKey;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    final language = context.select<LanguageBloc, String>((bloc) {
      final state = bloc.state;
      return state is LanguageChangedState ? state.language : 'ru';
    });
    _translateIfNeeded(language);

    final fill = stateSwitch
        ? (widget.fillColorDark ?? const Color(0xff192536))
        : (widget.fillColorLight ?? const Color(0xffEAE8EB));

    final List<TextInputFormatter> formatters = [];
    if (widget.fixedPlus) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }
    if (widget.isAuthName == true) {
      // Backend username rule: only Latin letters, digits and underscore
      // (no hyphen, no Cyrillic) — filter at input time instead of letting
      // the user hit a server-side rejection after submit.
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')));
    }
    formatters.add(LengthLimitingTextInputFormatter(widget.inputFormatters));

    final String translatedTitle = _translatedTitle;
    final String translatedErrorText = _translatedErrorText;
    final String? effectiveHint =
        (widget.hideHintOnFocus && _hasFocus && _isEmpty)
            ? null
            : translatedTitle;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        focusNode: _focusNode,
        autocorrect: false,
        enableSuggestions: false,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: formatters,
        initialValue: widget.controller == null ? widget.initValue : null,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        obscureText: widget.obscureText ?? false,
        controller: widget.controller,
        keyboardType: widget.textInputType,
        textInputAction: widget.textInputAction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return translatedErrorText.isNotEmpty ? translatedErrorText : null;
          }
          return null;
        },
        onChanged: (value) {
          widget.onChanged(value);

          if (widget.hideHintOnFocus) setState(() {});
        },
        decoration: InputDecoration(
          errorText: widget.isError == true && translatedErrorText.isNotEmpty
              ? translatedErrorText
              : null,
          prefixIcon: widget.path,
          prefixText: widget.fixedPlus ? '+' : null,
          prefixStyle: AppTextStyle.editAuthStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
          filled: widget.filledOverride ?? true,
          fillColor: fill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          hintText: effectiveHint,
          hintStyle: AppTextStyle.editAuthStyle,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20),
          ),
          errorStyle: const TextStyle(color: Colors.red),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          suffixIcon: widget.icon != null
              ? IconButton(
                  icon: Icon(widget.icon),
                  onPressed: widget.onPressed,
                )
              : null,
        ),
      ),
    );
  }
}

class CustomReviewTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool shouldValidate;

  const CustomReviewTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onPressed,
    this.icon,
    this.shouldValidate = true,
  });

  @override
  State<CustomReviewTextField> createState() => _CustomReviewTextFieldState();
}

class _CustomReviewTextFieldState extends State<CustomReviewTextField> {
  String? _translatedHint;
  String? _lastLanguage;
  String? _lastHintKey;
  int _translationVersion = 0;

  void _translateIfNeeded(String language) {
    final hintKey = widget.hintText ?? '';
    if (_lastLanguage == language && _lastHintKey == hintKey) return;

    _lastLanguage = language;
    _lastHintKey = hintKey;
    _translatedHint = hintKey;

    if (hintKey.isEmpty) return;

    final requestVersion = ++_translationVersion;
    context.read<LanguageBloc>().translateText(hintKey, language).then((value) {
      if (!mounted || requestVersion != _translationVersion) return;
      setState(() => _translatedHint = value);
    }).catchError((_) {
      if (!mounted || requestVersion != _translationVersion) return;
      setState(() => _translatedHint = hintKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    final language = context.select<LanguageBloc, String>((bloc) {
      final state = bloc.state;
      return state is LanguageChangedState ? state.language : 'ru';
    });
    _translateIfNeeded(language);

    final translatedHintText = _translatedHint ?? widget.hintText ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: widget.controller,
        autovalidateMode: widget.shouldValidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        inputFormatters: [LengthLimitingTextInputFormatter(400)],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Поле не может быть пустым';
          }
          if (value.length < 4) {
            return "Отзыв должен содержать не менее 4 символов";
          }
          return null;
        },
        onChanged: (value) {
          if (value.length <= 4) {
            Form.maybeOf(context)?.validate();
          }
        },
        decoration: InputDecoration(
          filled: true,
          fillColor:
              stateSwitch ? const Color(0xff192536) : const Color(0xffEAE8EB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          hintText: translatedHintText,
          hintStyle: AppTextStyle.editAuthStyle,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(20),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          suffixIcon: widget.icon,
        ),
      ),
    );
  }
}

class CustomEditReviewTextField extends StatefulWidget {
  const CustomEditReviewTextField({
    super.key,
    this.controller,
    this.onPressed,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final VoidCallback? onPressed;
  final int? inputFormatters;

  @override
  State<CustomEditReviewTextField> createState() =>
      _CustomEditReviewTextFieldState();
}

class _CustomEditReviewTextFieldState extends State<CustomEditReviewTextField> {
  String _translatedHintText = "Введите отзыв";
  String? _lastLanguage;
  int _translationVersion = 0;

  void _translateIfNeeded(String language) {
    if (_lastLanguage == language) return;

    _lastLanguage = language;
    final requestVersion = ++_translationVersion;
    const key = "Введите отзыв";

    context.read<LanguageBloc>().translateText(key, language).then((value) {
      if (!mounted || requestVersion != _translationVersion) return;
      setState(() => _translatedHintText = value);
    }).catchError((_) {
      if (!mounted || requestVersion != _translationVersion) return;
      setState(() => _translatedHintText = key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    final language = context.select<LanguageBloc, String>((bloc) {
      final state = bloc.state;
      return state is LanguageChangedState ? state.language : 'ru';
    });
    _translateIfNeeded(language);

    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: widget.controller,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.inputFormatters)
      ],
      decoration: InputDecoration(
        filled: true,
        fillColor:
            stateSwitch ? const Color(0xff192536) : const Color(0xffEAE8EB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        hintText: _translatedHintText,
        hintStyle: AppTextStyle.editAuthStyle,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(20),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
