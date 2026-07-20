import 'dart:io';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/document_bloc/document_bloc.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optombai/bloc/image_bloc/image_bloc.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/services/image_picker_service.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/message_show.dart';

class GalleryAboutUs extends StatefulWidget {
  const GalleryAboutUs({super.key, required this.user});

  final User user;

  @override
  State<GalleryAboutUs> createState() => _GalleryAboutUsState();
}

class _GalleryAboutUsState extends State<GalleryAboutUs> {
  List<File> imagesFile = [];

  showBottomPhoto(String id) {
    showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                    onPressed: () {
                      checkPhoto(ImageSource.gallery, id);
                    },
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
                    onPressed: () {
                      checkPhoto(ImageSource.camera, id);
                    },
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
                    Navigator.pop(context);
                  },
                  child: const TextTranslated(
                    "Отмена",
                  )),
            ));
  }

  void checkPhoto(ImageSource imageSource, String id) async {
    final imagePickerService = ImagePickerService();
    var images = await imagePickerService.pickImage(imageSource);
    if (images == null) {
      return;
    }
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
                      "Вы уверены что хотите добавить ?",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close))
                ],
              ),
              content: SizedBox(
                height: 300.h,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image(
                    image: FileImage(images),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              actions: [
                BlocConsumer<ImageBloc, ImageState>(
                  listener: (context, state) {
                    if (state.errors.isNotEmpty) {
                      showMessage(
                          context, state.errors, EnumStatusMessage.error);
                      Navigator.pop(context);
                    }
                    if (state.isSuccess) {
                      showMessage(context, ["Изображение успешно добавлено!"],
                          EnumStatusMessage.success);
                      BlocProvider.of<ImageBloc>(context)
                          .add(GetAllImage(widget.user.id));
                      Navigator.pop(context);
                    }
                  },
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        borderRadius: 20,
                        onPressed: () {
                          BlocProvider.of<ImageBloc>(context).add(
                              ImageCreateEvent(
                                  photos: images, userId: widget.user.id));
                        },
                        title: "Добавить",
                      ),
                    );
                  },
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    return Container(
      width: 180.w,
      height: 180.h,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color:
              stateSwitch ? const Color(0xff101A29) : const Color(0xffEDF3FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const TextTranslated(
            "Новое изображение",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: activeColor),
          ),
          SizedBox(
            height: 30.h,
          ),
          IconButton(
            onPressed: () {
              showBottomPhoto(widget.user.id);
            },
            icon: const Icon(
              Icons.add_circle_outline,
              size: 38,
            ),
          ),
          SizedBox(
            height: 5.h,
          ),
          const TextTranslated(
            "Добавить",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class DocumentImageAboutUs extends StatefulWidget {
  const DocumentImageAboutUs({super.key, required this.user});

  final User user;

  @override
  State<DocumentImageAboutUs> createState() => _DocumentImageAboutUsState();
}

class _DocumentImageAboutUsState extends State<DocumentImageAboutUs> {
  List<File> imagesFile = [];

  showBottomPhoto(String id) {
    showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                    onPressed: () {
                      checkPhoto(ImageSource.gallery, id);
                    },
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
                    onPressed: () {
                      checkPhoto(ImageSource.camera, id);
                    },
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
                    Navigator.pop(context);
                  },
                  child: const TextTranslated(
                    "Отмена",
                  )),
            ));
  }

  void checkPhoto(ImageSource imageSource, String id) async {
    final imagePickerService = ImagePickerService();
    var images = await imagePickerService.pickImage(imageSource);
    if (images == null) {
      return;
    }
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
                      "Вы уверены что хотите добавить ?",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close))
                ],
              ),
              content: SizedBox(
                height: 300.h,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image(
                    image: FileImage(images),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              actions: [
                BlocConsumer<DocumentBloc, DocumentState>(
                  listener: (context, state) {
                    if (state.errors.isNotEmpty) {
                      showMessage(
                          context, state.errors, EnumStatusMessage.error);
                      Navigator.pop(context);
                    }
                    if (state.isSuccess) {
                      showMessage(context, ["Изображение успешно добавлено!"],
                          EnumStatusMessage.success);
                      BlocProvider.of<DocumentBloc>(context)
                          .add(GetAllDocumentImage(widget.user.id));
                      Navigator.pop(context);
                    }
                  },
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        borderRadius: 20,
                        onPressed: () {
                          BlocProvider.of<DocumentBloc>(context).add(
                              DocumentImageCreateEvent(
                                  photos: images, userId: widget.user.id));
                        },
                        title: "Добавить",
                      ),
                    );
                  },
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    return Container(
      width: 180.w,
      height: 180.h,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color:
              stateSwitch ? const Color(0xff101A29) : const Color(0xffEDF3FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const TextTranslated(
            "Новое изображение",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: activeColor),
          ),
          SizedBox(
            height: 30.h,
          ),
          IconButton(
            onPressed: () {
              showBottomPhoto(widget.user.id);
            },
            icon: const Icon(
              Icons.add_circle_outline,
              size: 38,
            ),
          ),
          SizedBox(
            height: 5.h,
          ),
          const TextTranslated(
            "Добавить",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
