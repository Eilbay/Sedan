import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_bloc.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_event.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/services/image_picker_service.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/pages/profile/edit/widgets/market_request_block.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/utils/extensions/url_string_extension.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/card/card_filter.dart';
import 'package:optombai/widgets/utils/custom_avatar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/pages/add_product/product_type_config.dart';
import 'package:optombai/widgets/region/region_picker_sheet.dart';

@RoutePage()
class ProfileEditScreen extends StatefulWidget {
  final User user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  showBottomPhoto(String id) {
    showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                    onPressed: () => _pickAfterClosingSheet(
                        context, ImageSource.gallery, id),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.photo_on_rectangle,
                        ),
                        SizedBox(
                          width: 20.w,
                        ),
                        const TextTranslated(
                          "Выбрать из галереи",
                        ),
                      ],
                    )),
                CupertinoActionSheetAction(
                    onPressed: () => _pickAfterClosingSheet(
                        context, ImageSource.camera, id),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Icon(CupertinoIcons.camera),
                        SizedBox(
                          width: 20.w,
                        ),
                        const Center(
                          child: TextTranslated(
                            "Сделать снимок",
                          ),
                        ),
                      ],
                    ))
              ],
              cancelButton: CupertinoActionSheetAction(
                  onPressed: () {
                    context.router.maybePop();
                  },
                  child: const TextTranslated(
                    "Отмена",
                  )),
            ));
  }

  // The action sheet must close before the picker + confirm dialog open —
  // otherwise the confirm dialog renders underneath the still-open sheet
  // and looks like nothing happened until the screen is left and reopened.
  Future<void> _pickAfterClosingSheet(
    BuildContext sheetContext,
    ImageSource source,
    String id,
  ) async {
    sheetContext.router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    checkPhoto(source, id);
  }

  List<ChoseClass> listProviderAndManufacturer = [
    ChoseClass(id: 4, name: "Поставщик"),
    ChoseClass(id: 8, name: "Производитель"),
    ChoseClass(id: 16, name: "Покупатель"),
  ];

  void checkPhoto(ImageSource imageSource, String id) async {
    try {
      final imagePickerService = ImagePickerService();
      final picked = await imagePickerService.pickImage(imageSource);
      if (picked == null) {
        if (!mounted) return;
        showMessage(context, ["Не удалось получить изображение"],
            EnumStatusMessage.error);
        return;
      }

      final cropped = await imagePickerService.cropImage(picked);
      if (cropped == null) return;
      final images = cropped;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Row(
            children: [
              const Expanded(
                child: TextTranslated(
                  "Вы уверены что хотите изменить?",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                onPressed: () {
                  context.router.maybePop();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: CircleAvatar(
            radius: 80,
            backgroundImage: FileImage(images),
          ),
          actions: [
            BlocConsumer<UserBloc, UserState>(
              listener: (context, state) {
                if (state.errors.isNotEmpty) {
                  showMessage(context, state.errors, EnumStatusMessage.error);
                  context.router.maybePop();
                } else if (state.isSuccess) {
                  showMessage(
                    context,
                    ["Аватар изменено"],
                    EnumStatusMessage.success,
                  );
                  context.router.maybePop();
                  context.router.maybePop();
                }
              },
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    borderRadius: 20,
                    isLoading: state.isLoading,
                    onPressed: () {
                      BlocProvider.of<UserBloc>(context).add(
                        ImageUserUpdateEvent(file: images, id: id),
                      );
                    },
                    title: "Изменить",
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Camera capture error: $e");
      if (!mounted) return;
      showMessage(context, ["Ошибка при съемке"], EnumStatusMessage.error);
    }
  }

  Future<bool> checkPermissions(Permission permission) async {
    var status = await permission.status;

    if (status.isDenied || status.isRestricted) {
      status = await permission.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  late User user;
  final _formKey = GlobalKey<FormState>();
  String selectedValue = "";
  String countryValue = "";

  @override
  void initState() {
    user = User.copyWith(widget.user);
    super.initState();
    _checkPmtStatus();
  }

  void _checkPmtStatus() {
    context.read<PmtBloc>().add(const PmtStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    final id = context.select((UserBloc b) => b.state.user.id);
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: BorderSide.strokeAlignCenter,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
            onPressed: () {
              context.router.maybePop();
            },
            icon: const Icon(
              Icons.arrow_back,
              size: 27,
            )),
        actions: [
          _SaveButton(
            onSave: () {
              context
                  .read<UserBloc>()
                  .add(UserUpdateEvent(id: user.id, map: user.toJsonAdd()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 45),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AvatarSection(
                  user: user,
                  isDarkMode: stateSwitch,
                  onEditPressed: () => showBottomPhoto(user.id),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 35.h),
                    _LabeledTextField(
                      label: 'Имя',
                      errorText: "Hазвание компании",
                      initValue: user.username,
                      isName: true,
                      inputFormatters: 30,
                      maxLines: 1,
                      title: "Введите название компании",
                      onChanged: (value) {
                        setState(() {
                          user.username = value;
                        });
                      },
                    ),
                    SizedBox(height: 15.h),
                    _LabeledTextField(
                      label: 'Описание',
                      errorText: "Oписание",
                      initValue: user.description,
                      inputFormatters: 300,
                      isDesc: true,
                      minLines: 4,
                      maxLines: 6,
                      textInputType: TextInputType.multiline,
                      title: 'Введите описание компании',
                      onChanged: (value) {
                        setState(() {
                          user.description = value;
                        });
                      },
                    ),
                    SizedBox(height: 20.h),
                    _LabeledTextField(
                      label: 'Номер телефона',
                      errorText: "Номер телефона",
                      initValue: user.phone_number,
                      inputFormatters: 15,
                      maxLines: 1,
                      title: 'Введите номер телефона компании',
                      textInputType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          user.phone_number = value;
                        });
                      },
                    ),
                    SizedBox(height: 20.h),
                    _LabeledTextField(
                      label: 'Ссылка на сайт',
                      initValue: user.web_site.isNotEmpty ? user.web_site : "",
                      maxLines: 1,
                      title: 'Введите ссылку на сайт',
                      onChanged: (value) {
                        setState(() {
                          user.web_site = value.ensureHttpsPrefix();
                        });
                      },
                    ),
                    SizedBox(height: 20.h),
                    const _SocialLinksHeader(),
                    SizedBox(height: 15.h),
                    const _SocialIconsRow(),
                    SizedBox(height: 50.h),
                    _UserTypeDropdown(
                      userType: user.userType ?? '',
                      selectedValue: selectedValue,
                      items: listProviderAndManufacturer,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value.toString();
                          user.userType = selectedValue;

                          if (user.manufacturer_segment != 'clothing' &&
                              user.manufacturer_segment != 'other') {
                            user.manufacturer_segment = 'other';
                          }

                          user.about_us_data = {};
                        });
                      },
                    ),
                    SizedBox(height: 10.h),
                    if (user.userType == '4') ...[
                      MarketRequestBlock(
                        user: widget.user,
                      ),
                      SizedBox(height: 30.h),
                    ],
                    _EditableInfoRow(
                      label: 'Почта',
                      value: user.email,
                      onEditPressed: () {
                        context.router.push(const ProfileEditEmailRoute());
                      },
                    ),
                    SizedBox(height: 23.h),
                    _EditableInfoRow(
                      label: 'Пароль',
                      value: '**********',
                      isValueConst: true,
                      onEditPressed: () {
                        context.router.push(const ProfileEditPasswordRoute());
                      },
                    ),
                    SizedBox(height: 23.h),
                    _EditableInfoRow(
                      label: 'Регион',
                      value: user.region?.title ?? 'Не указан',
                      onEditPressed: () async {
                        final picked = await RegionPickerSheet.show(
                          context,
                          current: user.region,
                        );
                        if (!mounted) return;
                        setState(() => user.region = picked);
                      },
                    ),
                    SizedBox(height: 35.h),
                    SizedBox(height: 15.h),
                    _DeleteAccountButton(
                      isDarkMode: stateSwitch,
                      userId: user.id,
                    ),
                    SizedBox(height: 15.h),
                    _LogoutButton(
                      isDarkMode: stateSwitch,
                      userId: id,
                    ),
                    SizedBox(height: 50.h),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveButton({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      listener: (context, state) {
        if (state.errors.isNotEmpty) {
          showMessage(context, state.errors, EnumStatusMessage.error);
        }
        if (state.isSuccess) {
          showMessage(
              context, ["Профиль изменился"], EnumStatusMessage.success);
          context.router.maybePop();
        }
        if (state.isExit) {
          showMessage(
              context, ["Профиль успешно удален"], EnumStatusMessage.success);
          context.router.maybePop();
        }
      },
      builder: (context, state) {
        return IconButton(
            onPressed: onSave,
            icon: !state.isLoading
                ? const Icon(
                    Icons.done,
                    color: Colors.green,
                    size: 27,
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ));
      },
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final User user;
  final bool isDarkMode;
  final VoidCallback onEditPressed;

  const _AvatarSection({
    required this.user,
    required this.isDarkMode,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    // The screen edits a local copy of the user snapshotted in initState —
    // after an avatar upload only UserBloc carries the fresh image URL, so
    // read it reactively; otherwise the old photo stays until re-entry.
    final blocImage = context.select((UserBloc bloc) => bloc.state.user.image);
    final image = blocImage ?? user.image;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 110.w,
          height: 110.h,
          child: CircleAvatar(
              backgroundColor: const Color(0xffF0F0F0),
              backgroundImage:
                  image != null ? CachedNetworkImageProvider(image) : null,
              child: image == null
                  ? CustomAvatar(
                      sizeAvatar: 55,
                      width: 110.w,
                      height: 110.h,
                      size: 60,
                      colorContainer:
                          isDarkMode ? Colors.white10 : Colors.black12,
                      colorContainerBorder: Colors.black12,
                      image: null,
                    )
                  : null),
        ),
        Positioned(
            right: 0,
            bottom: 0,
            child: Container(
                width: 30.w,
                height: 30.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
                child: Center(
                    child: IconButton(
                  onPressed: onEditPressed,
                  icon: const Image(
                    image: AssetImage('assets/icons/edit.png'),
                    color: Colors.white,
                  ),
                ))))
      ],
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final String? errorText;
  final String? initValue;
  final bool isName;
  final bool isDesc;
  final int inputFormatters;
  final int? maxLines;
  final int? minLines;
  final String title;
  final TextInputType? textInputType;
  final ValueChanged<String> onChanged;

  const _LabeledTextField({
    required this.label,
    this.errorText,
    this.initValue,
    this.isName = false,
    this.isDesc = false,
    this.inputFormatters = 100,
    this.maxLines,
    this.minLines,
    required this.title,
    this.textInputType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextTranslated(label, style: AppTextStyle.editProfileText),
        SizedBox(height: 5.h),
        CustomTextField(
          errorText: errorText,
          initValue: initValue,
          isName: isName,
          isDesc: isDesc,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          minLines: minLines,
          title: title,
          textInputType: textInputType,
          onChanged: onChanged,
          obscureText: false,
        ),
      ],
    );
  }
}

class _SocialLinksHeader extends StatelessWidget {
  const _SocialLinksHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const TextTranslated(
          'Добавить доп. связь',
          style: AppTextStyle.editProfileText,
        ),
        IconButton(
            onPressed: () {
              context.router.push(const CreateSocialsRoute());
            },
            icon: const Icon(Icons.drive_file_rename_outline))
      ],
    );
  }
}

class _SocialIconsRow extends StatelessWidget {
  const _SocialIconsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SvgPicture.asset(
          "assets/icons/socials_dark/whats_icon.svg",
          width: 35.w,
        ),
        SvgPicture.asset(
          "assets/icons/socials_dark/insta_icon.svg",
          width: 35.w,
        ),
        SvgPicture.asset(
          "assets/icons/socials_dark/telegram_icon.svg",
          width: 35.w,
        ),
        SvgPicture.asset(
          "assets/icons/socials_dark/web_icon.svg",
          width: 35.w,
        ),
      ],
    );
  }
}

class _UserTypeDropdown extends StatelessWidget {
  final String userType;
  final String selectedValue;
  final List<ChoseClass> items;
  final ValueChanged<String?> onChanged;

  const _UserTypeDropdown({
    required this.userType,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  String _hintText() {
    switch (userType) {
      case '4':
        return "Поставщик";
      case '8':
        return "Производитель";
      case '16':
        return "Покупатель";
      default:
        return "Выберите тип пользователя";
    }
  }

  @override
  Widget build(BuildContext context) {
    return CardFilter(
      child: DropdownButton(
        underline: const SizedBox(),
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down),
        hint: TextTranslated(_hintText()),
        value: selectedValue.isNotEmpty ? selectedValue : null,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item.id.toString(),
            child: TextTranslated(item.name),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _EditableInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isValueConst;
  final VoidCallback onEditPressed;

  const _EditableInfoRow({
    required this.label,
    required this.value,
    this.isValueConst = false,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextTranslated(
              label,
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
            ),
            SizedBox(height: 5.h),
            isValueConst
                ? const TextTranslated(
                    "**********",
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                  )
                : TextTranslated(
                    value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w400, fontSize: 14),
                  ),
          ],
        ),
        IconButton(
            onPressed: onEditPressed,
            icon: const Icon(Icons.drive_file_rename_outline))
      ],
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  final bool isDarkMode;
  final String userId;

  const _DeleteAccountButton({
    required this.isDarkMode,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return _DeleteAccountDialog(
            isDarkMode: isDarkMode,
            userId: userId,
          );
        },
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TextTranslated(
            "Удалить аккаунт",
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(width: 20.w),
          const Icon(
            Icons.delete,
            color: Colors.white,
          )
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final bool isDarkMode;
  final String userId;

  const _DeleteAccountDialog({
    required this.isDarkMode,
    required this.userId,
  });

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          height: 220.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xff061324) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      context.router.maybePop();
                    },
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
              const TextTranslated(
                'Вы уверены, что хотите удалить аккаунт?',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15.h),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Введите пароль',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15.h),
              CustomButton(
                title: 'Удалить аккаунт',
                onPressed: () {
                  final password = _passwordController.text.trim();
                  if (password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: TextTranslated(
                          'Пароль не может быть пустым.',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  context
                      .read<UserBloc>()
                      .add(UserDeleteEvent(widget.userId, password));

                  context.read<UserBloc>().stream.listen((state) async {
                    if (state.isExit) {
                      if (!context.mounted) return;
                      debugPrint('[AUTH] account deleted from profile edit');
                      await context.read<AuthCubit>().clear(widget.userId);
                      if (!context.mounted) return;
                      context
                          .read<ThemeNotifier>()
                          .setRegistrationStatus(false);
                      context.router.replaceAll([
                        BottomNavRoute(initialIndex: 4),
                      ]);
                    }
                  });
                },
                isDelete: false,
                borderRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isDarkMode;
  final String userId;

  const _LogoutButton({
    required this.isDarkMode,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 15)),
      onPressed: () => showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return _LogoutDialog(
            isDarkMode: isDarkMode,
            userId: userId,
          );
        },
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TextTranslated(
            "Выйти",
            style: TextStyle(color: Colors.black),
          ),
          SizedBox(width: 20.w),
          const Icon(
            Icons.exit_to_app,
            color: Colors.black,
          )
        ],
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  final bool isDarkMode;
  final String userId;

  const _LogoutDialog({
    required this.isDarkMode,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        height: 150.h,
        width: double.infinity,
        decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xff061324) : Colors.white,
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    context.router.maybePop();
                  },
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
            const TextTranslated(
              'Вы действительно хотите выйти?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.h),
            CustomButton(
              title: 'Выйти',
              onPressed: () async {
                context.router.maybePop();
                debugPrint('[AUTH] logout from profile edit');
                await context.read<AuthCubit>().clear(userId);
                if (!context.mounted) return;
                context.read<ThemeNotifier>().setRegistrationStatus(false);
                // Wipe per-user caches so the next sign-in doesn't briefly
                // render the previous account's feed/profile/postModel
                // before its own data arrives.
                context.read<ProductBloc>().add(ClearProductsEvent());
                context.read<ProductBloc>().add(FetchAllProductsEvent());
                context.router.replaceAll([
                  BottomNavRoute(initialIndex: 4),
                ]);
              },
              borderRadius: 20,
            )
          ],
        ),
      ),
    );
  }
}
