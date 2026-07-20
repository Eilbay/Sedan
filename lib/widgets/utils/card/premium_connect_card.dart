
import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/core/form_status.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/profile/profile_contacts.dart';


class PremiumConnectCard extends StatelessWidget {
  final bool isCurrentUser;
  final User currentUser;
  final String? subscription;
  final User? currentActive;

  const PremiumConnectCard(
      {super.key,
      required this.currentUser,
      this.subscription,
      this.currentActive,
      required this.isCurrentUser});

  _launchWhatsapp(String urls) async {
    await launchUrl(Uri.parse(urls));
  }

  @override
  Widget build(BuildContext context) {
    bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    final bvState = context.watch<ButtonVisibleBloc>().state;
    final isHiddenMode = bvState.status == FormStatus.submissionSuccess &&
        !bvState.isVisible;

    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.user != current.user,
      builder: (context, state) {
        bool isPremium = currentUser.userStatus?.isPremium ?? false;

        if (!isRegister) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: activeColor,
            ),
            child: Column(
              children: [
                const Text(
                  "Авторизуйтесь для открытия контактов!",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5.h),
                SizedBox(height: 10.h),
                socialsDark(),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToSignIn(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      "Авторизоваться",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                )
              ],
            ),
          );
        }

        if (!isPremium) {
          if (isHiddenMode) return const SizedBox.shrink();
          return TariffButton(
            tariffName: 'Стандарт',
            showBusinessHint:
                !isCurrentUser && currentUser.userStatus?.isPremium != true,
            onTap: () {
              context.router.push(const ProAccountsRoute());
            },
          );
        }

        return VerificationNoticeCard(
          status:
              currentUser.userStatus?.isPremium == true ? 'Бизнес' : 'Стандарт',
          onVerifyTap: () => _launchWhatsapp("+996551947777"),
          isBuyer: currentUser.userType == "16" ? true : false,
        );
      },
    );
  }

  void _navigateToSignIn(BuildContext context) {
    context.router.push(const SignInRoute());
  }

  Row socialsDark() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Image(
            image: const AssetImage('assets/icons/socials_dark/phone_dark.png'),
            width: 30.w),
        Image(
            image: const AssetImage('assets/icons/socials_dark/whatsapp_dark.png'),
            width: 30.w),
        Image(
            image: const AssetImage('assets/icons/socials_dark/ins_dark.png'),
            width: 30.w),
        Image(
            image: const AssetImage('assets/icons/socials_dark/telegram_dark.png'),
            width: 30.w),
        const Image(image: AssetImage('assets/icons/socials_dark/earth_dark.png')),
      ],
    );
  }

  Row socialsDarkInCircle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SocialIconCircle(assetPath: 'assets/icons/socials_dark/phone_dark.png'),
        _SocialIconCircle(assetPath: 'assets/icons/socials_dark/whatsapp_dark.png'),
        _SocialIconCircle(assetPath: 'assets/icons/socials_dark/ins_dark.png'),
        _SocialIconCircle(assetPath: 'assets/icons/socials_dark/telegram_dark.png'),
        _SocialIconCircle(assetPath: 'assets/icons/socials_dark/earth_dark.png'),
      ],
    );
  }
}

class _SocialIconCircle extends StatelessWidget {
  final String assetPath;

  const _SocialIconCircle({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
      ),
      child: Center(
        child: Image.asset(
          assetPath,
          width: 20.w,
          color: Colors.white,
        ),
      ),
    );
  }
}

class TariffButton extends StatelessWidget {
  final String tariffName;
  final VoidCallback onTap;
  final bool showBusinessHint;

  const TariffButton({
    super.key,
    required this.tariffName,
    required this.onTap,
    this.showBusinessHint = false,
  });

  bool get isBusiness => tariffName.toLowerCase() == 'бизнес';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4169e1), Color(0xFF1e90ff)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12.w),
                Text('Ваш тариф ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                Text(
                  tariffName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.8), size: 16),
              ],
            ),
            if (!isBusiness) ...[
              SizedBox(height: 8.h),
              Text(
                'Разделы «Заказы» и «Покупатели» доступны только на тарифе «Бизнес»',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
