import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/data/mock/sedan_mock_listings.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/moderation/user_actions_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SedanMockDetailsPage extends StatefulWidget {
  const SedanMockDetailsPage({super.key, required this.listing});

  final SedanMockListing listing;

  @override
  State<SedanMockDetailsPage> createState() => _SedanMockDetailsPageState();
}

class _SedanMockDetailsPageState extends State<SedanMockDetailsPage> {
  bool _isSaved = false;
  int _financeIndex = 0;
  double _termMonths = 36;

  String get _usdPrice => widget.listing.price;

  String get _somPrice {
    final raw = widget.listing.price.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final usd = int.tryParse(raw) ?? 0;
    if (usd == 0) return widget.listing.price;
    return '${_formatNumber(usd * 89)} сом';
  }

  int get _monthlyPayment {
    final raw = widget.listing.price.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final usd = int.tryParse(raw) ?? 0;
    if (usd == 0) return 0;
    return (usd / _termMonths).round();
  }

  static String _formatNumber(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
                child: _TopBar(
                  listing: listing,
                  isSaved: _isSaved,
                  onBack: () => Navigator.of(context).maybePop(),
                  onSavedTap: () => setState(() => _isSaved = !_isSaved),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(15.w, 18.h, 15.w, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _HeroImage(listing: listing),
                  SizedBox(height: 14.h),
                  _SellerPriceCard(
                    listing: listing,
                    somPrice: _somPrice,
                    usdPrice: _usdPrice,
                  ),
                  SizedBox(height: 10.h),
                  _StatsRow(listing: listing),
                  SizedBox(height: 12.h),
                  _InfoRow(label: 'Название', value: listing.title),
                  _InfoRow(label: 'Описание', value: listing.condition),
                  const _InfoRow(label: 'Регион', value: 'Бишкек'),
                  SizedBox(height: 24.h),
                  const _SectionTitle('Кредит и финансирование'),
                  SizedBox(height: 12.h),
                  _FinanceTabs(
                    selectedIndex: _financeIndex,
                    onChanged: (index) => setState(() {
                      _financeIndex = index;
                    }),
                  ),
                  SizedBox(height: 12.h),
                  const _FinanceInfoCard(),
                  SizedBox(height: 14.h),
                  _FinanceCalculator(
                    price: _usdPrice,
                    termMonths: _termMonths,
                    monthlyPayment: _monthlyPayment,
                    onTermChanged: (value) => setState(() {
                      _termMonths = value;
                    }),
                  ),
                  SizedBox(height: 28.h),
                  _SimilarListingsSection(currentListing: listing),
                  SizedBox(height: 28.h),
                  Center(
                    child: Text(
                      'Авторизуйтесь чтобы оставить отзыв!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: kBottomNavigationBarHeight +
                        MediaQuery.viewPaddingOf(context).bottom +
                        28.h,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ContactButtonsRow(listing: listing),
          const BottomNav(
            currentIndexOverride: -1,
            passive: true,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.listing,
    required this.isSaved,
    required this.onBack,
    required this.onSavedTap,
  });

  final SedanMockListing listing;
  final bool isSaved;
  final VoidCallback onBack;
  final VoidCallback onSavedTap;

  // DEMO MODE
  static const _ownerId = 'mock-aibek-auto';
  static const _ownerUsername = 'Aibek.Auto';

  void _onShare() {
    final text = [
      listing.title,
      listing.price,
      'Смотри на Sedan.kg',
    ].join('\n');
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _onMore(BuildContext context) {
    UserActionsSheet.show(
      context,
      userId: _ownerId,
      username: _ownerUsername,
      reportTargetType: ReportTargetType.post,
      reportTargetId: 'mock-${sedanMockListings.indexOf(listing)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final fg = isDark ? Colors.white : Colors.black;

    return SizedBox(
      height: 54.h,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new, color: fg),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              listing.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            onPressed: onSavedTap,
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: fg,
            ),
          ),
          IconButton(
            onPressed: _onShare,
            icon: Icon(Icons.share, color: fg),
          ),
          IconButton(
            onPressed: () => _onMore(context),
            icon: Icon(Icons.more_vert, color: fg),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.listing});

  final SedanMockListing listing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Image.asset(listing.imageAsset, fit: BoxFit.cover),
      ),
    );
  }
}

/// DEMO MODE
const _mockOwnerId = 'mock-aibek-auto';
const _mockOwnerUsername = 'Aibek.Auto';

class _SellerPriceCard extends StatelessWidget {
  const _SellerPriceCard({
    required this.listing,
    required this.somPrice,
    required this.usdPrice,
  });

  final SedanMockListing listing;
  final String somPrice;
  final String usdPrice;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final fg = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.white70 : const Color(0xFF5F5F5F);
    final cardBg = isDark ? const Color(0xFF14181F) : Colors.white;
    final cardBorder =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.router.push(
        OtherUserProfileRoute(user: _mockOwnerId, username: _mockOwnerUsername),
      ),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.black,
              backgroundImage: AssetImage('assets/mock/mock_aibek.png'),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _mockOwnerUsername,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          color: Color(0xFF2F80ED), size: 18),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        'Рейтинг: 5.0',
                        style: TextStyle(color: sub, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star,
                          color: Color(0xFFFFA800), size: 14),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  usdPrice,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  somPrice,
                  style: const TextStyle(
                    color: Color(0xFF2F80ED),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.listing});

  final SedanMockListing listing;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final dotColor = isDark ? Colors.white38 : Colors.black26;
    final subColor = isDark ? Colors.white54 : const Color(0xFF7A7A7A);
    final articleNumber = 100000 + sedanMockListings.indexOf(listing);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        _StatsItem(
          icon: Icons.remove_red_eye_outlined,
          text: '${listing.views} просмотров',
        ),
        Text('•', style: TextStyle(color: dotColor, fontSize: 12)),
        const _StatsItem(
          icon: Icons.calendar_month_outlined,
          text: 'Добавлено недавно',
        ),
        Text('•', style: TextStyle(color: dotColor, fontSize: 12)),
        Text(
          'Арт: $articleNumber',
          style: TextStyle(color: subColor, fontSize: 12),
        ),
      ],
    );
  }
}

class _StatsItem extends StatelessWidget {
  const _StatsItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final subColor = isDark ? Colors.white54 : const Color(0xFF7A7A7A);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: subColor),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: subColor, fontSize: 12)),
      ],
    );
  }
}

// DEMO MODE
const _mockOwnerPhone = '0551947777';

class _ContactButtonsRow extends StatelessWidget {
  const _ContactButtonsRow({required this.listing});

  final SedanMockListing listing;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _mockOwnerPhone);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось позвонить')));
    }
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SedanMockChatScreen(listing: listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF2F80ED),
                ),
                label: const Text('Написать'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2F80ED),
                  side: const BorderSide(color: Color(0xFF2F80ED)),
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _call(context),
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text('Позвонить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockChatMessage {
  const _MockChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });

  final String text;
  final bool isMe;
  final DateTime time;
}

/// DEMO MODE
class SedanMockChatScreen extends StatefulWidget {
  const SedanMockChatScreen({super.key, this.listing});

  final SedanMockListing? listing;

  @override
  State<SedanMockChatScreen> createState() => _SedanMockChatScreenState();
}

class _SedanMockChatScreenState extends State<SedanMockChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<_MockChatMessage> _messages = [
    _MockChatMessage(
      text: widget.listing != null
          ? 'Здравствуйте! Спрашиваете по "${widget.listing!.title}"? '
              'С радостью отвечу на вопросы 🙂'
          : 'Здравствуйте! Чем можем помочь? 🙂',
      isMe: false,
      time: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _MockChatMessage(text: text, isMe: true, time: DateTime.now()),
      );
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _MockChatMessage(
            text: 'Спасибо за сообщение! Скоро отвечу.',
            isMe: false,
            time: DateTime.now(),
          ),
        );
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final fg = isDark ? Colors.white : Colors.black;
    final bubbleBg = isDark ? const Color(0xFF14181F) : const Color(0xFFF2F4F7);
    final dividerColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 4.h, 16.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_ios_new, color: fg),
                  ),
                  SizedBox(
                    width: 34.w,
                    height: 34.w,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/mock/mock_aibek.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Aibek.Auto',
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      constraints: BoxConstraints(maxWidth: 280.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            message.isMe ? const Color(0xFF2F80ED) : bubbleBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isMe ? Colors.white : fg,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12.w,
                8.h,
                12.w,
                8.h + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: fg),
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        filled: true,
                        fillColor: bubbleBg,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Material(
                    color: const Color(0xFF2F80ED),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _send,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BakAiLogo extends StatelessWidget {
  const _BakAiLogo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_balance, color: Color(0xFFE5234B), size: 20),
        SizedBox(width: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Bak',
                style: TextStyle(
                  color: Color(0xFFE5234B),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: 'Ai',
                style: TextStyle(
                  color: Color(0xFF2F80ED),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinanceTabs extends StatelessWidget {
  const _FinanceTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final unselected = isDark ? Colors.white70 : const Color(0xFF5F5F5F);
    const labels = ['Автофинансирование', 'Мурабаха'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181F) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(index),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: selected
                      ? Border.all(color: const Color(0xFF2F80ED), width: 1.5)
                      : null,
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selected ? const Color(0xFF2F80ED) : unselected,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FinanceInfoCard extends StatelessWidget {
  const _FinanceInfoCard();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final fg = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.white70 : const Color(0xFF5F5F5F);
    const items = [
      'Быстрое предварительное одобрение',
      'Первоначальный взнос от 30%',
      'Прозрачные условия',
      'Срок финансирования до 60 месяцев',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BakAiLogo(),
              SizedBox(height: 4.h),
              SizedBox(
                width: 90.w,
                child: const Text(
                  'Ваш инновационный мобильный банк',
                  style: TextStyle(fontSize: 10, color: Color(0xFF2F80ED)),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Финансирование автомобиля',
                  style: TextStyle(
                    color: fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12.h),
                for (final item in items)
                  Padding(
                    padding: EdgeInsets.only(bottom: 7.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check,
                          color: Color(0xFF2EB872),
                          size: 18,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              color: sub,
                              fontSize: 14,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceCalculator extends StatefulWidget {
  const _FinanceCalculator({
    required this.price,
    required this.termMonths,
    required this.monthlyPayment,
    required this.onTermChanged,
  });

  final String price;
  final double termMonths;
  final int monthlyPayment;
  final ValueChanged<double> onTermChanged;

  @override
  State<_FinanceCalculator> createState() => _FinanceCalculatorState();
}

class _FinanceCalculatorState extends State<_FinanceCalculator> {
  bool _consentAccepted = false;

  @override
  Widget build(BuildContext context) {
    final price = widget.price;
    final termMonths = widget.termMonths;
    final monthlyPayment = widget.monthlyPayment;
    final onTermChanged = widget.onTermChanged;
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final fg = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.white70 : const Color(0xFF5F5F5F);
    final sub2 = isDark ? Colors.white54 : const Color(0xFF7A7A7A);
    final editIconColor = isDark ? Colors.white60 : Colors.black45;
    final fieldBg =
        isDark ? Colors.black.withValues(alpha: 0.18) : const Color(0xFFF2F4F7);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Калькулятор',
                  style: TextStyle(
                    color: fg,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.edit_outlined, color: editIconColor, size: 18),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _CalculatorValue(label: 'Стоимость', value: price),
              ),
              const Expanded(
                child: _CalculatorValue(
                  label: 'Первоначальный взнос',
                  value: '30%',
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ежемесячный платёж',
                    style: TextStyle(color: sub),
                  ),
                ),
                Text(
                  '$monthlyPayment \$',
                  style: const TextStyle(
                    color: Color(0xFF2F80ED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text('Срок, месяцы', style: TextStyle(color: sub2)),
          Slider(
            min: 12,
            max: 60,
            divisions: 4,
            value: termMonths,
            activeColor: const Color(0xFF2F80ED),
            onChanged: onTermChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 мес.', style: TextStyle(color: sub2)),
              Text('60 мес.', style: TextStyle(color: sub2)),
            ],
          ),
          SizedBox(height: 18.h),
          InkWell(
            onTap: () => setState(() => _consentAccepted = !_consentAccepted),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: Checkbox(
                      value: _consentAccepted,
                      onChanged: (value) =>
                          setState(() => _consentAccepted = value ?? false),
                      activeColor: const Color(0xFF2F80ED),
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: _consentAccepted
                            ? const Color(0xFF2F80ED)
                            : (isDark
                                ? Colors.white38
                                : const Color(0xFF9AA4B2)),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style:
                            TextStyle(fontSize: 13, height: 1.35, color: sub),
                        children: const [
                          TextSpan(
                            text: 'Я даю согласие на передачу и обработку ',
                          ),
                          TextSpan(
                            text: 'персональных данных',
                            style: TextStyle(
                              color: Color(0xFF2F80ED),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _consentAccepted
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Заявка на автофинансирование'),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                disabledBackgroundColor:
                    const Color(0xFF2F80ED).withValues(alpha: 0.28),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF2F80ED),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Подать заявку',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorValue extends StatelessWidget {
  const _CalculatorValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final sub2 = isDark ? Colors.white54 : const Color(0xFF7A7A7A);
    final fg = isDark ? Colors.white : Colors.black;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: TextStyle(color: sub2, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              height: 1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final fg = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.white70 : const Color(0xFF5F5F5F);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 13.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: fg, fontWeight: FontWeight.w900),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor ?? sub),
            ),
          ],
        ),
      ),
    );
  }
}

/// DEMO MODE

class _SimilarListingsSection extends StatelessWidget {
  const _SimilarListingsSection({required this.currentListing});

  final SedanMockListing currentListing;

  @override
  Widget build(BuildContext context) {
    final others = sedanMockListings.where((l) => l != currentListing).toList()
      ..sort((a, b) {
        final aSame = a.categoryKey == currentListing.categoryKey ? 0 : 1;
        final bSame = b.categoryKey == currentListing.categoryKey ? 0 : 1;
        return aSame.compareTo(bSame);
      });

    if (others.isEmpty) return const SizedBox.shrink();
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Похожие объявления',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 210.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: others.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) =>
                _SimilarListingCard(listing: others[index]),
          ),
        ),
      ],
    );
  }
}

class _SimilarListingCard extends StatelessWidget {
  const _SimilarListingCard({required this.listing});

  final SedanMockListing listing;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SedanMockDetailsPage(listing: listing),
          ),
        );
      },
      child: Container(
        width: 150.w,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14181F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: Image.asset(listing.imageAsset, fit: BoxFit.cover),
            ),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    listing.price,
                    style: const TextStyle(
                      color: Color(0xFF2F80ED),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
