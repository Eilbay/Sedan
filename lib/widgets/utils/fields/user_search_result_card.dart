import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';

import 'package:optombai/data/models/account/user/user.dart';

class UserSearchResultCard extends StatelessWidget {
  final User user;

  const UserSearchResultCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl =
        user.image?.toString().trim();

    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    final username = user.username;
    final rating = user.rating;

    final int? productType =
        user.userType == null ? null : int.tryParse(user.userType!.toString());

    return ListTile(
      onTap: () {
        context.router.push(OtherUserProfileRoute(
          user: user.id,
          productType: productType,
          flagName: null,
          username: user.username,
        ));
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey.shade200,
        backgroundImage:
            hasAvatar ? CachedNetworkImageProvider(avatarUrl) : null,
        child: !hasAvatar ? const Icon(Icons.person, size: 18) : null,
      ),
      title: Text(
        username,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.star, size: 14, color: Colors.amber),
          SizedBox(width: 4.w),
          Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
