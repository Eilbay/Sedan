import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/features/promotion/domain/repository/promotion_repository.dart';
import 'package:optombai/features/promotion/presentation/logic/promotion_cubit.dart';
import 'package:optombai/widgets/app_scaffold/app_scaffold.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:auto_route/auto_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class PromotionsCampaignsScreen extends StatelessWidget {
  const PromotionsCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pushed standalone via auto_route, so it owns its cubit — there is no
    // ancestor BlocProvider<PromotionCubit> (only the promo dialog had one).
    // Providing it here prevents the "Could not find Provider" crash.
    return BlocProvider(
      create: (_) => PromotionCubit(
        repository: getIt<PromotionRepository>(),
        preferences: getIt<SharedPreferences>(),
      )..loadMyCampaigns(),
      child: const _PromotionsCampaignsView(),
    );
  }
}

class _PromotionsCampaignsView extends StatefulWidget {
  const _PromotionsCampaignsView();

  @override
  State<_PromotionsCampaignsView> createState() =>
      _PromotionsCampaignsViewState();
}

class _PromotionsCampaignsViewState extends State<_PromotionsCampaignsView> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return BazarlarAppScaffold(
      products: true,
      child: BlocBuilder<PromotionCubit, PromotionState>(
        buildWhen: (previous, current) =>
            previous.myCampaigns != current.myCampaigns ||
            previous.status != current.status,
        builder: (context, state) {
          if (state.myCampaigns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16.h),
                  TextTranslated(
                    'Нет активных кампаний',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextTranslated(
                    'Начните продвижение товара или видео',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.myCampaigns.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final campaign = state.myCampaigns[index];
              final daysRemaining = campaign.daysRemaining;
              final isActive = daysRemaining > 0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff192536) : Colors.white,
                  border: Border.all(
                    color: isActive
                        ? const Color(0xff0095D5)
                        : Colors.grey.shade300,
                    width: isActive ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextTranslated(
                                'Кампания ${index + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              TextTranslated(
                                'ID: ${campaign.postId.substring(0, 8)}...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextTranslated(
                            isActive ? 'Активна' : 'Завершена',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                SizedBox(width: 6.w),
                                TextTranslated(
                                  'Осталось: $daysRemaining д',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Colors.green.shade600,
                                ),
                                SizedBox(width: 6.w),
                                TextTranslated(
                                  campaign.reach != null
                                      ? 'Охват: ${_formatNumber(campaign.reach!.from)}-${_formatNumber(campaign.reach!.to)}'
                                      : 'Охват: N/A',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: isDark ? Colors.blue.shade300 : Colors.blue,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextTranslated(
                              'До ${_formatDate(campaign.endedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.blue.shade200
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
