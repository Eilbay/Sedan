import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/data/mock/sedan_mock_listings.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/moderation/user_actions_sheet.dart';
import 'package:share_plus/share_plus.dart';

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

    return Scaffold(
      backgroundColor: Colors.black,
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
                delegate: SliverChildListDelegate(
                  [
                    _HeroImage(listing: listing),
                    SizedBox(height: 14.h),
                    _SellerPriceCard(
                      listing: listing,
                      somPrice: _somPrice,
                      usdPrice: _usdPrice,
                    ),
                    SizedBox(height: 10.h),
                    _StatsRow(listing: listing),
                    SizedBox(height: 24.h),
                    const _SectionTitle('О товаре'),
                    SizedBox(height: 16.h),
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
                    const Center(
                      child: Text(
                        'Авторизуйтесь чтобы оставить отзыв!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ContactButtonsRow(listing: listing),
          const BottomNav(currentIndexOverride: -1, passive: true),
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
    return SizedBox(
      height: 54.h,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              listing.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            onPressed: onSavedTap,
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _onShare,
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _onMore(context),
            icon: const Icon(Icons.more_vert, color: Colors.white),
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.router.push(
        OtherUserProfileRoute(
          user: _mockOwnerId,
          username: _mockOwnerUsername,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFF14181F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.black,
              backgroundImage: AssetImage('assets/sedan.png'),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Flexible(
                        child: Text(
                          _mockOwnerUsername,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.verified, color: Color(0xFF2F80ED), size: 18),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  const Row(
                    children: [
                      Text('Рейтинг: 5.0',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.star, color: Color(0xFFFFA800), size: 14),
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
                  style: const TextStyle(
                    color: Colors.white,
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
    final articleNumber = 100000 + sedanMockListings.indexOf(listing);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        _StatsItem(
            icon: Icons.remove_red_eye_outlined,
            text: '${listing.views} просмотров'),
        const Text('•', style: TextStyle(color: Colors.white38, fontSize: 12)),
        const _StatsItem(
            icon: Icons.calendar_month_outlined, text: 'Добавлено недавно'),
        const Text('•', style: TextStyle(color: Colors.white38, fontSize: 12)),
        Text('Арт: $articleNumber',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _ContactButtonsRow extends StatelessWidget {
  const _ContactButtonsRow({required this.listing});

  final SedanMockListing listing;

  void _openOwner(BuildContext context) {
    context.router.push(
      OtherUserProfileRoute(
        user: _mockOwnerId,
        username: _mockOwnerUsername,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openOwner(context),
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Color(0xFF2F80ED)),
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
                onPressed: () => _openOwner(context),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
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
  const _FinanceTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Автофинансирование', 'Мурабаха'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
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
                      color:
                          selected ? const Color(0xFF2F80ED) : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
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
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                const Text(
                  'Финансирование автомобиля',
                  style: TextStyle(
                    color: Colors.white,
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
                        const Icon(Icons.check,
                            color: Color(0xFF2EB872), size: 18),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.white70,
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

class _FinanceCalculator extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Калькулятор',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.edit_outlined, color: Colors.white60, size: 18),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                  child: _CalculatorValue(label: 'Стоимость', value: price)),
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
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ежемесячный платёж',
                    style: TextStyle(color: Colors.white70),
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
          const Text('Срок, месяцы', style: TextStyle(color: Colors.white54)),
          Slider(
            min: 12,
            max: 60,
            divisions: 4,
            value: termMonths,
            activeColor: const Color(0xFF2F80ED),
            onChanged: onTermChanged,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 мес.', style: TextStyle(color: Colors.white54)),
              Text('60 мес.', style: TextStyle(color: Colors.white54)),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 15.h),
            decoration: BoxDecoration(
              color: const Color(0xFF2F80ED).withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Подать заявку',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 16,
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
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
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
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 13.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor ?? Colors.white70),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Похожие объявления',
          style: TextStyle(
            color: Colors.white,
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
          color: const Color(0xFF14181F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                    style: const TextStyle(
                      color: Colors.white,
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
