import 'dart:io';

enum MediaType { image, video }

class MediaFile {
  final File file;
  final MediaType type;
  final File? thumbnail;
  final int? size;
  final int? duration;

  MediaFile({
    required this.file,
    required this.type,
    this.thumbnail,
    this.size,
    this.duration,
  });

  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;

  String get formattedSize {
    if (size == null) return 'Unknown';
    final mb = size! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  MediaFile copyWith({
    File? file,
    MediaType? type,
    File? thumbnail,
    int? size,
    int? duration,
  }) {
    return MediaFile(
      file: file ?? this.file,
      type: type ?? this.type,
      thumbnail: thumbnail ?? this.thumbnail,
      size: size ?? this.size,
      duration: duration ?? this.duration,
    );
  }
}
