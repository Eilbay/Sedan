import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

@RoutePage()
class AdvertisingKabinetScreen extends StatelessWidget {
  const AdvertisingKabinetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return BazarlarAppScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const TextTranslated('Рекламный кабинет'),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            _KabinetMenuTile(
              icon: Icons.campaign_outlined,
              title: 'Мои кампании',
              subtitle: 'Активные и завершённые продвижения',
              isDarkMode: isDarkMode,
              onTap: () =>
                  context.router.push(const PromotionsCampaignsRoute()),
            ),
            SizedBox(height: 12.h),
            _KabinetMenuTile(
              icon: Icons.add_circle_outline,
              title: 'Создать кампанию',
              subtitle: 'Запустить продвижение товара',
              isDarkMode: isDarkMode,
              onTap: () => _showCreateCampaignHint(context, isDarkMode),
            ),
            SizedBox(height: 12.h),
            _KabinetMenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Рекламный баланс',
              subtitle: 'Пополнение и текущий баланс',
              isDarkMode: isDarkMode,
              onTap: () => context.router.push(const PitRoute()),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCampaignHint(BuildContext context, bool isDarkMode) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCampaignHintSheet(isDarkMode: isDarkMode),
    );
  }
}

class _KabinetMenuTile extends StatelessWidget {
  const _KabinetMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDarkMode,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xff797979).withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: const Color(0xff0095D5)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextTranslated(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TextTranslated(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CreateCampaignHintSheet extends StatelessWidget {
  const _CreateCampaignHintSheet({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff061324) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 14.h),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const TextTranslated(
            'Как создать кампанию',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          const _HintStep(
            number: '1',
            text: 'Откройте товар, который хотите продвигать.',
          ),
          SizedBox(height: 8.h),
          const _HintStep(
            number: '2',
            text: 'Нажмите кнопку «Продвигать» на карточке товара.',
          ),
          SizedBox(height: 8.h),
          const _HintStep(
            number: '3',
            text: 'Выберите пакет и подтвердите оплату с рекламного баланса.',
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0095D5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const TextTranslated(
                'Понятно',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintStep extends StatelessWidget {
  const _HintStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xff0095D5),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: TextTranslated(
            text,
            style: const TextStyle(fontSize: 13, height: 1.35),
          ),
        ),
      ],
    );
  }
}
