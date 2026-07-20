import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/pages/main_screen/widgets/market_status_badge.dart';
import 'package:optombai/widgets/common/rating_stars.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/profile/premium_badge.dart';
import 'package:optombai/widgets/profile/quality_badge.dart';
import 'package:optombai/widgets/profile/verified_badge.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class UserGridCard extends StatelessWidget {
  final User user;
  final bool isDarkMode;
  final int? choseOwner;
  final VoidCallback onTap;

  const UserGridCard({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.choseOwner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium =
        (user.isPremium ?? false) || (user.userStatus?.isPremium ?? false);
    final isVerified = (user.is_verified == true);
    final tier =
        (user.level != "empty") ? qualityTierForLevel(user.level!) : null;

    return GestureDetector(
      onTap: onTap,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 10,
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140.h,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: user.image != null
                        ? CachedNetworkImageProvider(user.image!)
                        : const AssetImage('assets/noImageUser.png')
                            as ImageProvider,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextTranslated(
                          user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        TextTranslated(
                          user.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        UserCountryRow(user: user),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 28,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: MarketStatusOneLine(user: user),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            RatingStars(rating: user.rating),
                            SizedBox(width: 10.w),
                            TextTranslated(
                              user.reviewsCount.toString(),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _QualityBadgePositioned(tier: tier),
                    _PremiumBadgePositioned(
                      isPremium: isPremium,
                      tier: tier,
                    ),
                    _VerifiedBadgePositioned(
                      isVerified: isVerified,
                      tier: tier,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserCountryRow extends StatelessWidget {
  final User user;

  const UserCountryRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (user.country?.name != null &&
            kCountryFlags.containsKey(user.country!.name))
          Image.asset(
            kCountryFlags[user.country!.name]!,
            width: 14.w,
            height: 14.w,
          ),
        if (user.country?.name != null) SizedBox(width: 6.w),
        Expanded(
          child: TextTranslated(
            user.country?.name ?? "Неизвестно",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _QualityBadgePositioned extends StatelessWidget {
  final QualityTier? tier;

  const _QualityBadgePositioned({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Visibility(
        visible: tier != null,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: QualityBadge(
          tier: tier ?? QualityTier.bronze,
          onTap: () {
            context.router.push(const UsersRoute());
          },
        ),
      ),
    );
  }
}

class _PremiumBadgePositioned extends StatelessWidget {
  final bool isPremium;
  final QualityTier? tier;

  const _PremiumBadgePositioned({
    required this.isPremium,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: (tier != null) ? 45.h : 20.h,
      child: isPremium
          ? BlocBuilder<ButtonVisibleBloc, ButtonVisibleState>(
              buildWhen: (p, c) =>
                  p.status != c.status ||
                  p.statusChangeMode != c.statusChangeMode,
              builder: (context, state) {
                if (state.isVisible) {
                  return InkWell(
                    onTap: () => context.router.push(const ProAccountsRoute()),
                    child: const PremiumBadge(),
                  );
                }
                return const SizedBox.shrink();
              },
            )
          : const SizedBox.shrink(),
    );
  }
}

class _VerifiedBadgePositioned extends StatelessWidget {
  final bool isVerified;
  final QualityTier? tier;

  const _VerifiedBadgePositioned({
    required this.isVerified,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: (tier != null) ? 26.h : 0,
      child: isVerified
          ? VerifiedBadge(
              onTap: () {
                context.router.push(const UsersRoute());
              },
            )
          : const SizedBox.shrink(),
    );
  }
}
