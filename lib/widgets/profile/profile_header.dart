import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/bloc/pit_bloc/pit_bloc.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/bloc/pit_bloc/pit_event.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/bloc/pit_bloc/pit_state.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/features/referral/presentation/logic/referral_cubit.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/bloc/subscription_bloc/subscription_bloc.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/bloc/subscription_bloc/subscription_event.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/bloc/subscription_bloc/subscription_state.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/data/models/subscription/subscription_plan_model.dart';
import 'package:optombai/utils/extensions/string_validation_extension.dart';
import 'package:optombai/utils/extensions/url_string_extension.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/bloc/feature_flags_cubit/gate/feature_flag_gate.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/data/models/account/user/socials/social_type.dart';
import 'package:optombai/utils/extensions/social_type_icon_extension.dart';
import 'package:optombai/widgets/utils/live_ring_avatar.dart';

class ProfileHeader extends StatefulWidget {
  final User currentUser;
  final bool isCurrentUser;
  final String? flagName;
  final int postCounts;

  final bool showInlineMenu;

  const ProfileHeader({
    super.key,
    this.flagName,
    required this.currentUser,
    required this.isCurrentUser,
    required this.postCounts,
    this.showInlineMenu = true,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  static const _green = Color(0xFF2EB872);
  static const _blue = Color(0xFF2F6BFF);

  static const _purple = Color(0xFF7B2FF2);
  static const _whatsapp = Color(0xFF25D366);
  static const _darkCard = Color(0xFF14181F);

  // STORE_RELEASE_HIDDEN_START: BUSINESS_SUBSCRIPTION

  // STORE_RELEASE_HIDDEN_END: BUSINESS_SUBSCRIPTION

  @override
  void initState() {
    super.initState();

    // STORE_RELEASE_HIDDEN_START: BUSINESS_AND_AD_WALLET_LOADING

    // STORE_RELEASE_HIDDEN_END: BUSINESS_AND_AD_WALLET_LOADING
  }

  /*
  STORE_RELEASE_HIDDEN_START: BUSINESS_AND_AD_WALLET_LOADING

  void _loadPitBalance() {
    if (widget.isCurrentUser) {
      context.read<PitBloc>().add(const LoadPitEvent());
    }
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

  STORE_RELEASE_HIDDEN_END: BUSINESS_AND_AD_WALLET_LOADING
  */

  void _launchPhoneNumber(String phoneNumber) async {
    final Uri phoneUrl = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    } else {
      throw "Can't phone that number.";
    }
  }

  Future<void> _launchUrlSafe(String url) async {
    await launchUrl(Uri.parse(url));
  }

  /*
  STORE_RELEASE_HIDDEN_START: AD_WALLET_HELPER

  static String _formatThousands(num v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  STORE_RELEASE_HIDDEN_END: AD_WALLET_HELPER
  */

  SocialOwner? _findSocial(String title) {
    for (final s in widget.currentUser.socials) {
      if (s.socialType.title.toLowerCase() == title.toLowerCase()) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final id = context.select((UserBloc b) => b.state.user.id);

    final canWrite =
        !widget.isCurrentUser && (widget.currentUser.by_admin != true);
    final isBlockedByMeReactive = widget.currentUser.isBlockedByMe ||
        context.select((BlockBloc b) =>
            b.state.blockedIds.contains(widget.currentUser.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _identityRow(context, isDark, id),
        SizedBox(height: 18.h),
        // STORE_RELEASE_HIDDEN_START: AD_WALLET_WIDGET

        // STORE_RELEASE_HIDDEN_END: AD_WALLET_WIDGET
        _statsRow(isDark),
        SizedBox(height: 22.h),
        _descriptionBlock(context, isDark),
        SizedBox(height: 18.h),
        if (canWrite && !isBlockedByMeReactive) _contactCards(context, isDark),
      ],
    );
  }

  void _showOptionsSheet(BuildContext context, bool isDark, String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? _darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isCurrentUser) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const TextTranslated('Редактировать профиль'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.router
                        .push(ProfileEditRoute(user: widget.currentUser));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const TextTranslated(
                    'Выйти',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _confirmLogout(context, id);
                  },
                ),
              ] else
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const TextTranslated('Пожаловаться'),
                  onTap: () => Navigator.pop(sheetCtx),
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, String id) {
    final bool isDark = context.read<ThemeNotifier>().isDarkMode;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 150.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff061324) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
                const TextTranslated(
                  'Вы действительно хотите выйти?',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10.h),
                CustomButton(
                  title: 'Выйти',
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    debugPrint('[AUTH] logout from profile header');
                    await context.read<AuthCubit>().clear(id);
                    if (!context.mounted) return;
                    context.read<ThemeNotifier>().setRegistrationStatus(false);
                    context.router.replaceAll([
                      BottomNavRoute(initialIndex: 4),
                    ]);
                  },
                  borderRadius: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _identityRow(BuildContext context, bool isDark, String id) {
    final user = widget.currentUser;

    final typeLabel = user.userType == '4'
        ? 'Поставщик'
        : user.userType == '8'
            ? 'Производитель'
            : user.userType == '16'
                ? 'Покупатель'
                : user.userType == '1'
                    ? 'Админ'
                    : 'Неизвестный тип';

    final marketBadges = <Widget>[];
    if (user.userType == '4' && user.supplierMarkets.isNotEmpty) {
      for (final m in user.supplierMarkets.where((m) => m.isActive)) {
        marketBadges.add(_checkPill(m.marketName, isDark: isDark));
      }
    }
    final verified = user.is_verified ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileAvatarRing(user: user),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextTranslated(
                      user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.showInlineMenu)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => _showOptionsSheet(context, isDark, id),
                      icon: Icon(
                        Icons.more_horiz,
                        size: 24,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  TextTranslated(
                    typeLabel,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (user.country?.square_flag != null) ...[
                    SizedBox(width: 6.w),
                    TextTranslated(user.country!.square_flag!),
                  ],
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Stars(rating: user.rating),
                  SizedBox(width: 8.w),
                  TextTranslated(
                    '${user.rating.toInt()}/5',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...marketBadges,
                  if (verified) _checkPill('Проверен', isDark: isDark),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  const TextTranslated(
                    'Активно отвечает',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkPill(String label, {required bool isDark}) {
    return Container(
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
            width: 12,
            height: 12,
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
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardDecorationChild({required bool isDark, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? _darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  /*
  STORE_RELEASE_HIDDEN_START: AD_WALLET

  Widget _walletRow(BuildContext context, bool isDark) {
    final userFlag = context.read<UserBloc>().state.user.country?.square_flag;
    final referralState = context.select((ReferralCubit c) => c.state);
    final currency = _resolveCurrencySymbolOrName(
      referralState: referralState,
      userFlag: userFlag,
    );

    return BlocBuilder<PitBloc, PitState>(
      buildWhen: (p, c) => p.balance != c.balance || p.isLoading != c.isLoading,
      builder: (context, s) {
        final balanceText = s.isLoading ? '…' : _formatThousands(s.balance);

        return _cardDecorationChild(
          isDark: isDark,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: _purple, size: 24),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextTranslated(
                      'Рекламный кошелек',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            balanceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 0.h),
                          child: Text(
                            currency,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FeatureFlagGate(
                flagKey: 'walletTopUp',
                child: Row(
                  children: [
                    SizedBox(width: 8.w),
                    SizedBox(
                      height: 24.h,
                      child: ElevatedButton(
                        onPressed: () async {
                          await context.router.push(const PitRoute());
                          if (context.mounted) {
                            context.read<PitBloc>().add(const LoadPitEvent());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const TextTranslated(
                          'Пополнить',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 10),
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
  }

  STORE_RELEASE_HIDDEN_END: AD_WALLET
  */

  Widget _statsRow(bool isDark) {
    return _cardDecorationChild(
      isDark: isDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(widget.postCounts.toString(), 'Товаров'),
          _statDivider(isDark),
          _statItem(widget.currentUser.rating.toInt().toString(), 'Рейтинг'),
          _statDivider(isDark),
          _statItem(widget.currentUser.reviewsCount.toString(), 'Отзывы'),
        ],
      ),
    );
  }

  Widget _statDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        TextTranslated(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4.h),
        TextTranslated(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _descriptionBlock(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DescriptionWidget(description: widget.currentUser.description),
        if (widget.currentUser.web_site.isNotEmpty) ...[
          SizedBox(height: 8.h),
          InkWell(
            onTap: () => _launchUrlSafe(widget.currentUser.web_site),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextTranslated(widget.currentUser.web_site.stripHttpsPrefix()),
                SizedBox(width: 5.w),
                const Icon(Icons.language, color: Colors.blue),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _contactCards(BuildContext context, bool isDark) {
    final whatsapp = _findSocial('WhatsApp');
    final hasPhone = widget.currentUser.phone_number.trim().isNotEmpty;

    final cards = <Widget>[];

    if (whatsapp != null) {
      cards.add(_contactCard(
        isDark: isDark,
        icon: Icons.chat,
        iconColor: Colors.white,
        iconBg: _whatsapp,
        title: 'Написать\nв WhatsApp',
        subtitle: 'Быстрый ответ',
        onTap: () =>
            _launchUrlSafe(whatsapp.socialType.domainUrl + whatsapp.link),
      ));
    }

    cards.add(_contactCard(
      isDark: isDark,
      icon: Icons.forum_rounded,
      iconColor: _purple,
      iconBg: _purple.withValues(alpha: 0.12),
      title: 'Написать\nв чат',
      subtitle: 'Ответим здесь',
      onTap: () => _openChat(context),
    ));

    if (hasPhone) {
      cards.add(_contactCard(
        isDark: isDark,
        icon: Icons.call,
        iconColor: _blue,
        iconBg: _blue.withValues(alpha: 0.12),
        title: 'Позвонить',
        subtitle: 'Связаться\nпо телефону',
        onTap: () => _launchPhoneNumber(widget.currentUser.phone_number),
      ));
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: 10.w),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }

  Widget _contactCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? _darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(height: 10.h),
            TextTranslated(
              title,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 2.h),
            TextTranslated(
              subtitle,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final bool isRegister = context.read<ThemeNotifier>().isRegister;
    if (!isRegister) {
      debugPrint('[AUTH] profile header chat gate -> sign in');
      context.router.push(const SignInRoute());
      return;
    }

    final targetUserId = widget.currentUser.id;
    if (!targetUserId.isValidUuid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить пользователя')),
      );
      return;
    }

    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(CreatePersonalChatEvent(targetUserId));

    try {
      final state = await chatBloc.stream.firstWhere((s) {
        final hasChatForUser = s.chats.any(
          (c) => c.participants.any((p) => p.id == targetUserId),
        );
        return !s.isLoading && (hasChatForUser || s.errors.isNotEmpty);
      }).timeout(const Duration(seconds: 12));

      if (!context.mounted) return;

      if (state.errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errors.join(', '))),
        );
        return;
      }

      final chat = state.chats.firstWhere(
        (c) => c.participants.any((p) => p.id == targetUserId),
        orElse: () => state.chats.first,
      );
      context.router.push(ChatConversationRoute(chat: chat));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть чат')),
      );
    }
  }
}

/// Renders a social network's icon in a unified local style when the
/// network is known, falling back to the backend-provided logo URL for
/// networks this app doesn't ship a local icon for yet.
class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.socialType});

  final SocialType socialType;

  @override
  Widget build(BuildContext context) {
    final localAsset = socialType.localIconAsset;

    if (localAsset != null) {
      return Image.asset(localAsset, height: 33.h, width: 33.w);
    }

    return CachedNetworkImage(
      imageUrl: socialType.logo,
      height: 33.h,
      width: 33.w,
      errorWidget: (_, __, ___) => const Icon(Icons.error),
    );
  }
}

class ProfileTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ProfileTabBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const _green = Color(0xFF2EB872);

  @override
  Widget build(BuildContext context) {
    final tabs = ['Объявления', 'О нас', 'Отзывы'];
    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = i == selectedIndex;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(i),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Column(
                children: [
                  TextTranslated(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? _green : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 2,
                    color: selected ? _green : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/*
STORE_RELEASE_HIDDEN_START: AD_WALLET_CURRENCY

String _resolveCurrencySymbolOrName({
  required ReferralState referralState,
  required String? userFlag,
}) {
  const fallback = 'KGS';
  final currencies = referralState.currencies;
  if (currencies.isEmpty || userFlag == null || userFlag.isEmpty) {
    return fallback;
  }
  final match = currencies
      .where((c) => c.squareFlag == userFlag)
      .map((c) => c.name)
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return match.isNotEmpty ? match.first.toUpperCase() : fallback;
}

STORE_RELEASE_HIDDEN_END: AD_WALLET_CURRENCY
*/

class DescriptionWidget extends StatefulWidget {
  final String description;
  const DescriptionWidget({super.key, required this.description});

  @override
  State<DescriptionWidget> createState() => _DescriptionWidgetState();
}

class _DescriptionWidgetState extends State<DescriptionWidget> {
  bool isExpanded = false;
  static const int maxLinesCollapsed = 5;
  bool showExpandButton = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkTextOverflow();
    });
  }

  void _checkTextOverflow() {
    if (!mounted) return;
    final textPainter = TextPainter(
      text: TextSpan(text: widget.description, style: AppTextStyle.profileText),
      maxLines: maxLinesCollapsed,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.sizeOf(context).width);

    if (!mounted) return;
    setState(() => showExpandButton = textPainter.didExceedMaxLines);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextTranslated(
          widget.description.isNotEmpty
              ? widget.description
              : 'Описание магазина',
          maxLines: isExpanded ? null : maxLinesCollapsed,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: widget.description.isEmpty
              ? TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white : Colors.black54,
                )
              : AppTextStyle.profileText,
        ),
        SizedBox(height: 5.h),
        if (showExpandButton)
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: TextTranslated(
              isExpanded ? 'Скрыть' : 'Показать больше',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
      ],
    );
  }
}

class _ProfileAvatarRing extends StatelessWidget {
  const _ProfileAvatarRing({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92.w,
      height: 92.w,
      child: LiveRingAvatar(
        radius: 46.w,
        ownerId: user.id,
        imageUrl: user.image,
        child: user.image == null
            ? Icon(Icons.person, size: 44, color: Colors.grey.shade500)
            : null,
        notLiveRingBuilder: (avatar) => Container(
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.red, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: avatar,
        ),
      ),
    );
  }
}
