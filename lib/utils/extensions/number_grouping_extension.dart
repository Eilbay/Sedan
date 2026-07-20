/// Groups a number's integer digits by thousands with a space separator,
/// e.g. 17490 -> "17 490". Used for price display across product cards.
extension NumberGroupingExtension on num {
  String get groupedByThousands {
    final digits = round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
