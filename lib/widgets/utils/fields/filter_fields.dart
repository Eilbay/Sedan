import 'package:flutter/material.dart';

class FilterFields extends StatelessWidget {
  final Function onChange;
  final String? hint;

  const FilterFields({super.key, required this.onChange, this.hint});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        hintText: hint,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        onChange(value);
      },
    );
  }
}
