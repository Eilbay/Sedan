extension IntFormatExtension on int {
  /// Format number: 1000 → 1.0K, 1000000 → 1.0M
  String toCompactFormat() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }
}
