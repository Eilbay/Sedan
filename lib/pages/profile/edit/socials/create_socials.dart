import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/bloc/social_bloc/social_types/social_types_bloc.dart';

@RoutePage(name: 'CreateSocialsRoute')
class CreateSocials extends StatefulWidget {
  const CreateSocials({super.key});

  @override
  State<CreateSocials> createState() => _CreateSocialsState();
}

class _CreateSocialsState extends State<CreateSocials> {
  void showAlertDialog(SocialOwner socialOwner, EnumRequestType typeRequest) {
    String getHintText(String socialTypeId) {
      if (socialTypeId == "WhatsApp") {
        return 'номер телефона без +';
      } else if (socialTypeId == "Telegram") {
        return 'номер телефона начиная с +, или ник';
      } else if (socialTypeId == "Instagram") {
        return 'ваш ник в Instagram';
      }
      return 'нет соц.сетей c data base';
    }

    String currentLink = socialOwner.link;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialogForLinks(
              title: "Социальная сеть",
              buttonTitle:
                  typeRequest == EnumRequestType.put ? "Изменить" : "Добавить",
              initialLink: socialOwner.link,
              onChange: (value) {
                currentLink = value;
              },
              onPressed: () {
                final updated = socialOwner.copyWith(link: currentLink);
                BlocProvider.of<UserBloc>(context).add(
                  SocialOwnerEvent(updated, typeRequest),
                );
              },
              icon: socialOwner.socialType.logo,
              hintText: getHintText(socialOwner.socialType.title));
        });
  }

  void showDeleteDialog(SocialOwner socialOwner) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                const Expanded(
                  child: TextTranslated(
                    "Вы уверены что хотите удалить?",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      context.router.maybePop();
                    },
                    icon: const Icon(Icons.close))
              ],
            ),
            actions: [
              BlocConsumer<UserBloc, UserState>(
                buildWhen: (previous, current) =>
                    previous.isLoading != current.isLoading,
                listenWhen: (previous, current) =>
                    previous.errors != current.errors ||
                    previous.isSuccessSocials != current.isSuccessSocials,
                listener: (context, state) {
                  if (state.errors.isNotEmpty) {
                    showMessage(context, state.errors, EnumStatusMessage.error);
                  }
                  if (state.isSuccessSocials) {
                    showMessage(context, ["Соц.сеть удаленa"],
                        EnumStatusMessage.success);

                    context.router.maybePop();
                  }
                },
                builder: (context, state) {
                  return CustomButton(
                    borderRadius: 20,
                    isLoading: state.isLoading,
                    onPressed: () {
                      BlocProvider.of<UserBloc>(context).add(
                        SocialOwnerEvent(socialOwner, EnumRequestType.delete),
                      );
                    },
                    title: "Удалить",
                  );
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var user = context.select((UserBloc b) => b.state.user);

    return BlocProvider(
      create: (context) => SocialTypesBloc(repository: getIt<IUserRepository>())..add(SocialsGetEvent()),
      child: BlocBuilder<SocialTypesBloc, SocialTypesState>(
        buildWhen: (previous, current) =>
            previous.socialsTypes != current.socialsTypes ||
            previous.errors != current.errors,
        builder: (context, state) {
          if (state.errors.isNotEmpty) {
            return const Scaffold(
              body: Center(
                child: TextTranslated(
                  "Ошибка!",
                  style: TextStyle(fontSize: 17, color: Colors.red),
                ),
              ),
            );
          }
          /*
          if (state.socialsTypes.isEmpty) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }*/

          return Scaffold(
            floatingActionButton: SpeedDial(
              activeIcon: Icons.close,
              icon: Icons.add,
              iconTheme: const IconThemeData(
                color: Colors.white,
              ),
              spacing: 10,
              children: state.socialsTypes
                  .map(
                    (item) => SpeedDialChild(
                      onTap: () {
                        SocialOwner socialOwner = SocialOwner(
                            id: 0, socialType: item, link: "", owner: user.id);

                        showAlertDialog(socialOwner, EnumRequestType.post);
                      },
                      child: CachedNetworkImage(
                        imageUrl: item.logo,
                        width: 30.w,
                        errorWidget: (_, __, ___) => const Icon(Icons.error),
                      ),
                    ),
                  )
                  .toList(),
              backgroundColor: const Color(0xff738CAB),
            ),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: const TextTranslated(
                "Социальные сети",
                style: TextStyle(fontSize: 25),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    SizedBox(
                      height: 20.h,
                    ),
                    ...user.socials.toList().map((item) => Card(
                          child: ListTile(
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      showDeleteDialog(item);
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    )),
                                IconButton(
                                    onPressed: () {
                                      showAlertDialog(
                                          item, EnumRequestType.put);
                                    },
                                    icon: const Icon(
                                      Icons.drive_file_rename_outline,
                                      color: Colors.indigo,
                                    )),
                              ],
                            ),
                            title: TextTranslated(item.socialType.title),
                            subtitle: TextTranslated(item.link),
                            leading: CachedNetworkImage(
                              imageUrl: item.socialType.logo,
                              height: 23.h,
                              width: 23.w,
                              errorWidget: (_, __, ___) => const Icon(Icons.error),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AlertDialogForLinks extends StatelessWidget {
  const AlertDialogForLinks(
      {super.key,
      required this.onChange,
      required this.onPressed,
      required this.initialLink,
      required this.hintText,
      required this.title,
      required this.buttonTitle,
      required this.icon});

  final Function onChange;
  final VoidCallback onPressed;
  final String initialLink;
  final String hintText;
  final String title;
  final String buttonTitle;
  final String icon;

  @override
  Widget build(BuildContext context) {
    debugPrint(icon);

    return AlertDialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CachedNetworkImage(
            imageUrl: icon,
            height: 23.h,
            width: 23.w,
            errorWidget: (_, __, ___) => const Icon(Icons.error),
          ),
          Flexible(
            child: TextTranslated(
              title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          InkWell(
            onTap: () {
              context.router.maybePop();
            },
            child: const Icon(Icons.close),
          )
        ],
      ),
      content: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Поле не может быть пустым';
          }
          return null;
        },
        initialValue: initialLink,
        decoration: InputDecoration(
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.red)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.red)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
          helperText: hintText,
          hintText: 'Введите',
          hintStyle: const TextStyle(fontSize: 14),
        ),
        onChanged: (value) {
          onChange(value);
        },
      ),
      actions: [
        BlocConsumer<UserBloc, UserState>(
          buildWhen: (previous, current) =>
              previous.isLoading != current.isLoading,
          listenWhen: (previous, current) =>
              previous.errors != current.errors ||
              previous.isSuccessSocials != current.isSuccessSocials,
          listener: (context, state) {
            if (state.errors.isNotEmpty) {
              showMessage(context, state.errors, EnumStatusMessage.error);
            }
            if (state.isSuccessSocials) {
              showMessage(
                context,
                ["Добавленa соц.сеть"],
                EnumStatusMessage.success,
              );
              context.router.maybePop();
            }
          },
          builder: (context, state) {
            return CustomButton(
              borderRadius: 20,
              isLoading: state.isLoading,
              onPressed: onPressed,
              title: buttonTitle,
            );
          },
        ),
      ],
    );
  }
}
