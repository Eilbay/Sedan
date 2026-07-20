import 'package:equatable/equatable.dart';

/// Response shape of POST /api/v2/post-media/.
///
/// Returned `id` is later included in `media_ids: [...]` when calling
/// POST /api/v2/posts/ to atomically create the post with its media.
class PostMediaV2 extends Equatable {
  final int id;
  final String image;
  final bool isVideo;

  const PostMediaV2({
    required this.id,
    required this.image,
    required this.isVideo,
  });

  factory PostMediaV2.fromJson(Map<String, dynamic> json) {
    return PostMediaV2(
      id: json['id'] as int,
      image: (json['image'] ?? '') as String,
      isVideo: json['is_video'] == true,
    );
  }

  @override
  List<Object?> get props => [id, image, isVideo];
}
