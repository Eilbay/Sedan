import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class RequisitesCard extends StatelessWidget {
  const RequisitesCard(
      {super.key, required this.user, required this.isCurrentUser});

  final bool isCurrentUser;

  final User user;

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color:
              stateSwitch ? const Color(0xff101A29) : const Color(0xffEDF3FF)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const TextTranslated(
                "Реквизиты",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              if (isCurrentUser)
                IconButton(
                    onPressed: () => context.router.push(
                        RequisitesEditRoute(user: user)),
                    icon: const Icon(
                      Icons.drive_file_rename_outline_rounded,
                      color: Color(0xC95F5F5F),
                    ))
            ],
          ),

          //Image.asset('assets/about_us.png'),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: stateSwitch ? Colors.transparent : Colors.white
                // color: Colors.white,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                requestsCard("Наименование организации:",
                    user.username.isNotEmpty ? user.username : "Отсутствует"),
                requestsCard(
                    "ИНН:", user.itn.isNotEmpty ? user.itn : "Отсутствует"),
                requestsCard(
                    "Юридический адрес:",
                    user.legalAddress.isNotEmpty
                        ? user.legalAddress
                        : "Отсутствует"),
                requestsCard("Директор:",
                    user.director.isNotEmpty ? user.director : "Отсутствует"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Container requestsCard(String title, String subTitle) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xffCFDEFB)))),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextTranslated(
            title,
            style: const TextStyle(color: Color(0xff7F7F7F)),
          ),
          SizedBox(
            height: 6.h,
          ),
          TextTranslated(subTitle)
        ],
      ),
    );
  }
}
