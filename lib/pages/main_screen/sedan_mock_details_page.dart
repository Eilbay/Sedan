import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/data/mock/sedan_mock_listings.dart';
import 'package:optombai/widgets/bottom_nav.dart';

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
    final categoryTitle = sedanMockCategoryTitleForKey(listing.categoryKey);

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar:
          const BottomNav(currentIndexOverride: -1, passive: true),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
                child: _TopBar(
                  title: listing.title,
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
                    _PriceRow(
                      somPrice: _somPrice,
                      usdPrice: _usdPrice,
                      views: 128,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      listing.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    const _SellerCard(),
                    SizedBox(height: 24.h),
                    const _SectionTitle('Описание'),
                    SizedBox(height: 10.h),
                    Text(
                      listing.condition,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 26.h),
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
                    SizedBox(height: 24.h),
                    const _SectionTitle('О товаре'),
                    SizedBox(height: 16.h),
                    _InfoRow(label: 'Название', value: listing.title),
                    _InfoRow(
                      label: 'Категория',
                      value: categoryTitle,
                      valueColor: const Color(0xFF2F80ED),
                    ),
                    for (final spec in listing.specs)
                      _InfoRow(label: spec.label, value: spec.value),
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
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isSaved,
    required this.onBack,
    required this.onSavedTap,
  });

  final String title;
  final bool isSaved;
  final VoidCallback onBack;
  final VoidCallback onSavedTap;

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
              title.toUpperCase(),
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
            onPressed: () {},
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
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
    final specs = listing.specs;
    final year = specs.isNotEmpty ? specs.first.value : '-';
    final engine = specs.length > 1 ? specs[1].value : '-';
    final category = sedanMockCategoryTitleForKey(listing.categoryKey);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(listing.imageAsset, fit: BoxFit.cover),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 20.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeroSpec(value: year, label: 'ГОД'),
                  _HeroSpec(value: engine, label: 'ДВИГАТЕЛЬ'),
                  _HeroSpec(value: category, label: 'КАТЕГОРИЯ'),
                ],
              ),
            ),
            Positioned(
              bottom: 8.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80ED),
                    shape: BoxShape.circle,
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

class _HeroSpec extends StatelessWidget {
  const _HeroSpec({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value\n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.1,
              ),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.somPrice,
    required this.usdPrice,
    required this.views,
  });

  final String somPrice;
  final String usdPrice;
  final int views;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: const Color(0xFF2F80ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            somPrice,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          usdPrice,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        const Icon(Icons.remove_red_eye_outlined, color: Colors.white70),
        SizedBox(width: 4.w),
        Text(views.toString(), style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard();

  // DEMO MODE
  static const _ownerId = 'mock-aibek-auto';
  static const _ownerUsername = 'Aibek.Auto';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.router.push(
        OtherUserProfileRoute(
          user: _ownerId,
          username: _ownerUsername,
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
            const Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _ownerUsername,
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
            ),
            const Icon(Icons.chevron_right, color: Colors.white60),
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

class _FinanceTabs extends StatelessWidget {
  const _FinanceTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Кредит', 'Лизинг', 'Рассрочка'];
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
                    color: selected ? const Color(0xFF2F80ED) : Colors.white70,
                    fontWeight: FontWeight.w800,
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
                  const Icon(Icons.check, color: Color(0xFF2EB872), size: 18),
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
