extension VideoUrlExtension on String {
  bool get isVideoUrl {
    final lower = toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm');
  }
}
