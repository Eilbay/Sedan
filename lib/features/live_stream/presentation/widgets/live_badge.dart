import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Red "on air" badge shown in the live room (viewer) and on the
/// broadcaster's screen, next to the viewers counter.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  static const _liveColor = Color(0xFFFF004D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _liveColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/live_broadcast.svg',
            width: 10,
            height: 10,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 3),
          const Text(
            "В ЭФИРЕ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
