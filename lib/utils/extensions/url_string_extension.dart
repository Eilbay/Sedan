extension UrlStringExtension on String {
  /// Ensures the URL starts with https:// prefix.
  String ensureHttpsPrefix() {
    if (!startsWith("http://") && !startsWith("https://")) {
      return "https://$this";
    }
    return this;
  }

  /// Strips the https:// prefix for display purposes.
  String stripHttpsPrefix() {
    if (startsWith("https://")) {
      return replaceFirst("https://", "");
    }
    return this;
  }
}
