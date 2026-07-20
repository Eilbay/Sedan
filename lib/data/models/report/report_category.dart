/// Backend-aligned report categories.
enum ReportCategory {
  spam('spam', 'Спам'),
  nsfw('nsfw', 'Неприемлемый контент (18+)'),
  harassment('harassment', 'Оскорбления / травля'),
  fraud('fraud', 'Мошенничество'),
  copyright('copyright', 'Нарушение авторских прав'),
  other('other', 'Другое');

  const ReportCategory(this.wireValue, this.label);

  final String wireValue;
  final String label;

  bool get requiresReason => this == ReportCategory.other;

  static ReportCategory fromWire(String value) {
    return ReportCategory.values.firstWhere(
      (c) => c.wireValue == value,
      orElse: () => ReportCategory.other,
    );
  }
}
