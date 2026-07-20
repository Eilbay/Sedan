import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';

class PhoneNumberInput extends StatefulWidget {
  final void Function(String completePhoneNumber)? onChanged;
  final TextEditingController controller;

  const PhoneNumberInput({super.key, this.onChanged, required this.controller});

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  String selectedCountryId = '1';
  int maxPhoneLength = 9;

  String _hintText = "Введите номер телефона";
  String _emptyErrorText = "Пожалуйста, введите номер телефона";
  String _invalidCharacterText = "Пожалуйста, введите только цифры";
  String _wrongLengthTemplate =
      "Номер телефона должен состоять из {maxPhoneLength} цифр";
  String? _lastLanguage;
  int _translationVersion = 0;

  final List<Map<String, dynamic>> countries = [
    {
      'id': "1",
      'name': 'Кыргызстан',
      'code': '+996',
      'flag': '🇰🇬',
      'maxLength': 9
    },
    {
      'id': "2",
      'name': 'Россия',
      'code': '+7',
      'flag': '🇷🇺',
      'maxLength': 10
    },
    {
      'id': "3",
      'name': 'Казахстан',
      'code': '+7',
      'flag': '🇰🇿',
      'maxLength': 10
    },
    {
      'id': "4",
      'name': 'Узбекистан',
      'code': '+998',
      'flag': '🇺🇿',
      'maxLength': 9
    },
    {
      'id': "5",
      'name': 'Белоруссия',
      'code': '+375',
      'flag': '🇧🇾',
      'maxLength': 11
    },
    {
      'id': "6",
      'name': 'Турция',
      'code': '+90',
      'flag': '🇹🇷',
      'maxLength': 10
    },
    {
      'id': "7",
      'name': 'Италия',
      'code': '+39',
      'flag': '🇮🇹',
      'maxLength': 12
    },
  ];

  Map<String, dynamic> get _country =>
      countries.firstWhere((c) => c['id'] == selectedCountryId);

  String get _code => _country['code'] as String;

  @override
  void initState() {
    super.initState();
    maxPhoneLength = _country['maxLength'] as int;
  }

  void _translateIfNeeded(String language) {
    if (_lastLanguage == language) return;

    _lastLanguage = language;
    final requestVersion = ++_translationVersion;

    Future.wait([
      context
          .read<LanguageBloc>()
          .translateText("Введите номер телефона", language),
      context
          .read<LanguageBloc>()
          .translateText("Пожалуйста, введите номер телефона", language),
      context
          .read<LanguageBloc>()
          .translateText("Пожалуйста, введите только цифры", language),
      context.read<LanguageBloc>().translateText(
          "Номер телефона должен состоять из {maxPhoneLength} цифр", language),
    ]).then((values) {
      if (!mounted || requestVersion != _translationVersion) return;
      setState(() {
        _hintText = values[0];
        _emptyErrorText = values[1];
        _invalidCharacterText = values[2];
        _wrongLengthTemplate = values[3];
      });
    }).catchError((_) {
      if (!mounted || requestVersion != _translationVersion) return;
    });
  }

  void _notify() {
    widget.onChanged?.call('$_code${widget.controller.text}');
  }

  @override
  Widget build(BuildContext context) {
    final language = context.select<LanguageBloc, String>((bloc) {
      final state = bloc.state;
      return state is LanguageChangedState ? state.language : 'ru';
    });
    _translateIfNeeded(language);

    final wrongLengthText = _wrongLengthTemplate.replaceAll(
        "{maxPhoneLength}", maxPhoneLength.toString());

    return Row(
      children: [
        DropdownButton<String>(
          value: selectedCountryId,
          underline: const SizedBox.shrink(),
          onChanged: (String? newId) {
            if (newId == null) return;
            setState(() {
              selectedCountryId = newId;
              maxPhoneLength = _country['maxLength'] as int;

              if (widget.controller.text.length > maxPhoneLength) {
                widget.controller.text =
                    widget.controller.text.substring(0, maxPhoneLength);
                widget.controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: widget.controller.text.length),
                );
              }
            });
            _notify();
          },
          items: countries.map((country) {
            return DropdownMenuItem<String>(
              value: country['id'] as String,
              child: Row(
                children: [
                  Text(country['flag'] as String),
                  SizedBox(width: 6.w),
                  Text(country['code'] as String),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: [
              LengthLimitingTextInputFormatter(maxPhoneLength),
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (_) => _notify(),
            decoration: InputDecoration(
              hintText: _hintText,
              errorStyle: const TextStyle(color: Colors.red),
              errorMaxLines: 2,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return _emptyErrorText;
              }
              if (RegExp(r'[^\d]').hasMatch(value)) {
                return _invalidCharacterText;
              }
              if (value.length != maxPhoneLength) {
                return wrongLengthText;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
