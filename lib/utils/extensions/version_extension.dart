extension VersionExtension on String {
  /// Compares two semantic version strings (`"2.0.242"` style), part by
  /// part, numerically — a plain string compare would rank `"2.9"` above
  /// `"2.10"`. Returns negative if this version is older than [other], zero
  /// if equal, positive if newer. Non-numeric/missing parts count as 0.
  int compareToVersion(String other) {
    final a = split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final b = other.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final length = a.length > b.length ? a.length : b.length;

    for (var i = 0; i < length; i++) {
      final aPart = i < a.length ? a[i] : 0;
      final bPart = i < b.length ? b[i] : 0;
      if (aPart != bPart) return aPart.compareTo(bPart);
    }
    return 0;
  }

  bool isOlderVersionThan(String other) => compareToVersion(other) < 0;
}
