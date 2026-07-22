import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomScaffold extends StatelessWidget {
  final Widget child;
  final Widget? leading;
  final List<Widget>? action;
  final String title;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final VoidCallback? onRefresh;

  const CustomScaffold({
    super.key,
    required this.child,
    required this.title,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onRefresh,
    this.leading,
    this.action,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    String displayTitle =
        title.length > 29 ? '${title.substring(0, 29)}...' : title;

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: Scaffold(
        floatingActionButtonLocation: floatingActionButtonLocation ??
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: floatingActionButton,
        appBar: AppBar(
          leading: leading,
          iconTheme: IconThemeData(
              color: stateSwitch ? Colors.white : Colors.black, size: 30),
          elevation: 0,
          actions: [
            if (action != null) ...action!,
          ],
          flexibleSpace: stateSwitch
              ? Container(color: AppColors.black)
              : Container(color: AppColors.white),
          title: Row(
            children: [
              /*Image.asset(
                stateSwitch
                    ? 'assets/logo_light.png'
                    : 'assets/logo_bazarlar.png',
                height: 28.h,
                fit: BoxFit.contain,
              ),*/
              SizedBox(width: 10.w),
              TextTranslated(displayTitle,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium)
            ],
          ),
        ),
        body: child,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
