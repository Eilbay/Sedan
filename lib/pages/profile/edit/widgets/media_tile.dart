import 'package:optombai/core/import_links.dart';
import 'package:optombai/utils/extensions/video_url_extension.dart';

class MediaTile extends StatelessWidget {
  const MediaTile({super.key, required this.url, this.coverUrl});

  final String url;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final video = url.isVideoUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!video)
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
          )
        else if (coverUrl != null)
          CachedNetworkImage(
            imageUrl: coverUrl!,
            fit: BoxFit.cover,
          )
        else
          Container(
            color: const Color(0xFF0B0B0F),
          ),
        if (video)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x40000000),
                ],
              ),
            ),
          ),
        if (video)
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 30),
            ),
          ),
      ],
    );
  }
}
