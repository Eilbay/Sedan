import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/core/import_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/profile/premium_badge.dart';
import 'package:optombai/widgets/profile/quality_badge.dart';
import 'package:optombai/widgets/profile/verified_badge.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class ProductOwnerGridCard extends StatelessWidget {
  final Product product;
  final bool isDarkMode;
  final VoidCallback onTap;

  const ProductOwnerGridCard({
    super.key,
    required this.product,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final owner = product.owner!;
    final isPremium =
        (owner.isPremium ?? false) || (owner.userStatus?.isPremium ?? false);
    final isVerified = owner.is_verified!;
    final hasTier = owner.level != "empty" &&
        qualityTierForLevel(owner.level!) != null;

    return GestureDetector(
      onTap: onTap,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 10,
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (owner.image != null)
                Container(
                  height: 170.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: owner.image != null
                          ? CachedNetworkImageProvider(owner.image)
                          : const AssetImage('assets/notfound.png')
                              as ImageProvider,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(1.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextTranslated(
                      owner.username,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    TextTranslated(
                      owner.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _BadgesRow(
                              isPremium: isPremium,
                              isVerified: isVerified,
                            ),
                            SizedBox(height: 3.h),
                            if (hasTier)
                              QualityBadge(
                                onTap: () {
                                  context.router.push(const UsersRoute());
                                },
                                tier: qualityTierForLevel(owner.level!)!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgesRow extends StatelessWidget {
  final bool isPremium;
  final bool isVerified;

  const _BadgesRow({
    required this.isPremium,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPremium)
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: BlocBuilder<ButtonVisibleBloc, ButtonVisibleState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.statusChangeMode != current.statusChangeMode,
              builder: (context, state) {
                if (state.isVisible) {
                  return InkWell(
                    onTap: () => context.router.push(const ProAccountsRoute()),
                    child: const PremiumBadge(),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        if (isVerified)
          VerifiedBadge(
            onTap: () {
              context.router.push(const UsersRoute());
            },
          ),
      ],
    );
  }
}
