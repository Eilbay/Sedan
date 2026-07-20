import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage(name: 'RequisitesEditRoute')
class RequisitesEdit extends StatefulWidget {
  const RequisitesEdit({super.key, required this.user});

  final User user;

  @override
  State<RequisitesEdit> createState() => _RequisitesEditState();
}

class _RequisitesEditState extends State<RequisitesEdit> {
  TextEditingController nameController = TextEditingController();
  TextEditingController innController = TextEditingController();
  TextEditingController adressController = TextEditingController();
  TextEditingController directorController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  late User user;
  String selectedValue = "";

  @override
  void initState() {
    user = User.copyWith(widget.user);
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    innController.dispose();
    adressController.dispose();
    directorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: BlocConsumer<UserBloc, UserState>(
            listener: (context, state) {},
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextTranslated(
                      "Редактировать реквизиты",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    SizedBox(
                      height: 25.h,
                    ),
                    const TextTranslated('Наименование организации:',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      initValue: user.username,
                      errorText: '"Наименование организации:"',
                      inputFormatters: 300,
                      maxLines: 1,
                      title: 'Введите текст',
                      onChanged: (value) {
                        setState(() {
                          user.username = value;
                        });
                      },
                      obscureText: false,
                      textInputType: TextInputType.text,
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    const TextTranslated('ИНН:',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      initValue: user.itn,
                      errorText: '"ИНН:"',
                      inputFormatters: 300,
                      maxLines: 1,
                      title: 'Введите текст',
                      onChanged: (value) {
                        user.itn = value;
                      },
                      obscureText: false,
                      textInputType: TextInputType.text,
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    const TextTranslated('Юридический адрес:',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      initValue: user.legalAddress,
                      errorText: '"Юридический адрес:"',
                      inputFormatters: 300,
                      maxLines: 1,
                      title: 'Введите текст',
                      onChanged: (value) {
                        user.legalAddress = value;
                      },
                      obscureText: false,
                      textInputType: TextInputType.text,
                    ),
                    SizedBox(height: 20.h),
                    const TextTranslated('Директор:',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12)),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      initValue: user.director,
                      errorText: '"Директор:"',
                      inputFormatters: 300,
                      maxLines: 1,
                      title: 'Введите текст',
                      onChanged: (value) {
                        user.director = value;
                      },
                      obscureText: false,
                      textInputType: TextInputType.text,
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    BlocConsumer<UserBloc, UserState>(
                      listener: (context, state) {
                        if (state.errors.isNotEmpty) {
                          showMessage(
                              context, state.errors, EnumStatusMessage.error);
                        }
                        if (state.isSuccess) {
                          showMessage(context, ["Сохранено"],
                              EnumStatusMessage.success);
                        }
                      },
                      builder: (context, state) {
                        return CustomButton(
                          title: "Сохранить",
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            context.read<UserBloc>().add(UserUpdateEvent(
                                id: user.id, map: user.toJsonAdd()));
                            showMessage(context, ["Сохранено"],
                                EnumStatusMessage.success);
                            context.router.maybePop();
                          },
                          borderRadius: 20,
                        );
                      },
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
