import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_event.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_state.dart';
import 'package:optombai/data/models/subscription/subscription_plan_model.dart';
import 'package:optombai/utils/extensions/url_string_extension.dart';
import 'package:optombai/widgets/profile/quality_badge.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/form_status.dart';
import 'package:optombai/widgets/utils/card/premium_connect_card.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/profile/profile_header.dart';

class SecondHeader extends StatefulWidget {
  final User currentUser;
  final bool isCurrentUser;

  /// Total products count from /posts/?owner=... — overrides
  /// [User.postsCount] when provided, so both ProfileHeader and SecondHeader
  /// show a single canonical number.
  final int? postCounts;

  const SecondHeader({
    super.key,
    required this.currentUser,
    required this.isCurrentUser,
    this.postCounts,
  });

  @override
  State<SecondHeader> createState() => _SecondHeaderState();
}

class _SecondHeaderState extends State<SecondHeader> {
  static const _green = Color(0xFF2EB872);
  static const _darkCard = Color(0xFF14181F);

  List<SubscriptionPlan?> allPlans = const [];
  StreamSubscription<SubscriptionState>? _subsSub;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionDetails();
  }

  void _fetchSubscriptionDetails() {
    context.read<SubscriptionBloc>().add(FetchSubscriptionEvent());
    _subsSub?.cancel();
    _subsSub = context.read<SubscriptionBloc>().stream.listen((state) {
      if (state is SubscriptionLoaded) {
        if (!mounted) return;
        setState(() => allPlans = state.plans);
      }
    });
  }

  @override
  void dispose() {
    _subsSub?.cancel();
    super.dispose();
  }

  Future<void> _launchWeb(String urls) async {
    await launchUrl(Uri.parse(urls));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    final id = context.select((UserBloc b) => b.state.user.id);

    final user = widget.currentUser;
    final userActive = user.userActive;

    final bool showPhoneAndShare =
        (user.userStatus?.isPremium ?? false) == false &&
            id == user.id &&
            userActive != null &&
            (userActive.profileViewCount ?? 0) > 0 &&
            (userActive.profileViewsCountManafacturer ?? 0) > 0;

    SubscriptionPlan? selectedPlan;
    if (user.userActive?.premium != null) {
      try {
        selectedPlan = allPlans.firstWhere(
          (plan) => plan?.id == user.userActive!.premium,
          orElse: () => null,
        );
      } catch (_) {
        selectedPlan = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(context, isDark),
        SizedBox(height: 12.h),
        _identityRow(context, isDark),
        SizedBox(height: 18.h),
        _statsRow(),
        SizedBox(height: 20.h),
        _typeAndBadges(context, isDark),
        SizedBox(height: 10.h),
        DescriptionWidget(description: user.description),
        SizedBox(height: 8.h),
        _countryRow(user),
        if (user.web_site.isNotEmpty) ...[
          SizedBox(height: 8.h),
          _websiteRow(user),
        ],
        SizedBox(height: 12.h),
        _freeViewsOrPremium(
          context,
          isRegister: isRegister,
          showPhoneAndShare: showPhoneAndShare,
          selectedPlan: selectedPlan,
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, bool isDark) {
    final fg = isDark ? Colors.white : Colors.black54;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TextTranslated(
            widget.currentUser.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        if (widget.isCurrentUser)
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () =>
                context.router.push(ProfileEditRoute(user: widget.currentUser)),
            icon: Image.asset('assets/icons/edit_profile.png', color: fg),
          ),
      ],
    );
  }

  Widget _identityRow(BuildContext context, bool isDark) {
    final user = widget.currentUser;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 92.w,
          height: 92.w,
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.red, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xffF0F0F0),
            backgroundImage: user.image != null
                ? CachedNetworkImageProvider(user.image)
                : null,
            child: user.image == null
                ? Icon(Icons.person, size: 44, color: Colors.grey.shade500)
                : null,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                (widget.postCounts ?? user.postsCount).toString(),
                'Публикаций',
              ),
              _statItem(user.rating.toString(), 'Рейтинг'),
              _statItem(user.reviewsCount.toString(), 'Отзывы'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsRow() => const SizedBox.shrink();

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        TextTranslated(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4.h),
        TextTranslated(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _typeAndBadges(BuildContext context, bool isDark) {
    final user = widget.currentUser;
    final verified = user.is_verified ?? false;
    final hasQuality =
        user.level != 'empty' && qualityTierForLevel(user.level!) != null;
    final isPremium =
        (user.isPremium ?? false) || (user.userStatus?.isPremium ?? false);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextTranslated(
          user.userType == '4' ? 'Поставщик' : 'Производитель',
          style: const TextStyle(color: Colors.grey),
        ),
        if (verified)
          _checkPill(
            'Проверен',
            isDark: isDark,
            onTap: () => context.router.push(const UsersRoute()),
          ),
        if (hasQuality)
          _checkPill(
            'Качество',
            isDark: isDark,
            onTap: () => context.router.push(const UsersRoute()),
          ),
        if (user.userType == '4')
          ...user.supplierMarkets.where((m) => m.isActive).map(
                (m) => _checkPill(m.marketName, isDark: isDark),
              ),
        if (isPremium)
          BlocBuilder<ButtonVisibleBloc, ButtonVisibleState>(
            buildWhen: (p, c) =>
                p.status != c.status ||
                p.statusChangeMode != c.statusChangeMode,
            builder: (context, state) {
              if (state.status == FormStatus.submissionSuccess &&
                  state.isVisible) {
                return _checkPill(
                  'Premium',
                  isDark: isDark,
                  onTap: () => context.router.push(const ProAccountsRoute()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _checkPill(String label, {required bool isDark, VoidCallback? onTap}) {
    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: isDark ? _darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          SizedBox(width: 6.w),
          TextTranslated(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: pill,
    );
  }

  Widget _countryRow(User user) {
    if (user.country == null) return const SizedBox.shrink();
    return Row(
      children: [
        TextTranslated(user.country!.name),
        SizedBox(width: 8.w),
        if (user.country!.square_flag != null)
          TextTranslated(user.country!.square_flag!),
      ],
    );
  }

  Widget _websiteRow(User user) {
    return InkWell(
      onTap: () => _launchWeb(user.web_site),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextTranslated(user.web_site.stripHttpsPrefix()),
          SizedBox(width: 5.w),
          const Icon(Icons.language, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _freeViewsOrPremium(
    BuildContext context, {
    required bool isRegister,
    required bool showPhoneAndShare,
    required SubscriptionPlan? selectedPlan,
  }) {
    if (showPhoneAndShare) {
      return BlocBuilder<UserBloc, UserState>(
        buildWhen: (p, c) => p.userActive != c.userActive,
        builder: (context, state) {
          final viewsWithCount = state.userActive.where((ua) {
            final v = double.tryParse(ua.profileViewCount.toString());
            return v != null && v > 0;
          });
          final totalProfileViews = viewsWithCount.fold<int>(
            0,
            (sum, ua) =>
                sum + (int.tryParse(ua.profileViewCount.toString()) ?? 0),
          );
          return Row(
            children: [
              const TextTranslated('Бесплатный просмотр Заказы: '),
              TextTranslated(
                totalProfileViews.toString(),
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          );
        },
      );
    }

    return BlocBuilder<ButtonVisibleBloc, ButtonVisibleState>(
      buildWhen: (p, c) =>
          p.status != c.status || p.statusChangeMode != c.statusChangeMode,
      builder: (context, state) {
        final visible =
            (state.status == FormStatus.submissionSuccess && state.isVisible) ||
                !isRegister;
        if (visible) {
          return PremiumConnectCard(
            isCurrentUser: widget.isCurrentUser,
            currentUser: widget.currentUser,
            subscription: selectedPlan?.title ?? '',
          );
        }
        return SizedBox(height: 20.h);
      },
    );
  }
}
