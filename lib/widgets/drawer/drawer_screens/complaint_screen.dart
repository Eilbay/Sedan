import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/question_bloc/question_bloc.dart';
import 'package:optombai/data/models/question/question_model.dart';
import 'package:optombai/widgets/app_scaffold/custom_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:optombai/configs/app_style.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key, required this.question});

  final QuestionModel question;

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController complaintController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    complaintController.dispose();
    super.dispose();
  }

  final bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
        bottomNavigationBar: const BottomNav(
          currentIndexOverride: -1,
          passive: true,
        ),
        title: '',
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 30.h,
                  ),
                  const TextTranslated(
                    'Оставьте жалобу или предложение',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                  SizedBox(
                    height: 25.h,
                  ),
                  const TextTranslated('Имя',
                      style: AppTextStyle.editProfileText),
                  SizedBox(
                    height: 5.h,
                  ),
                  CustomTextField(
                    controller: nameController,
                    errorText: '"Имя"',
                    isName: true,
                    inputFormatters: 30,
                    maxLines: 1,
                    title: "Введите ваше имя",
                    onChanged: (value) {
                      setState(() {
                        widget.question.name = value;
                      });
                    },
                    obscureText: false,
                    textInputType: TextInputType.name,
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  const TextTranslated(
                    'Почта',
                    style: AppTextStyle.editProfileText,
                  ),
                  SizedBox(
                    height: 5.h,
                  ),
                  CustomTextField(
                    controller: emailController,
                    errorText: '"E-mail"',
                    inputFormatters: 50,
                    maxLines: 1,
                    title: 'Введите ваш e-mail',
                    onChanged: (value) {
                      setState(() {
                        widget.question.email = value;
                      });
                    },
                    obscureText: false,
                    textInputType: TextInputType.emailAddress,
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  const TextTranslated('Tелефон',
                      style: AppTextStyle.editProfileText),
                  SizedBox(
                    height: 5.h,
                  ),
                  CustomTextField(
                    isNumber: true,
                    controller: phoneController,
                    errorText: '"Tелефон"',
                    inputFormatters: 17,
                    maxLines: 1,
                    title: 'Введите ваш телефон (+996...)',
                    fixedPlus: true,
                    onChanged: (value) {
                      setState(() {
                        widget.question.phoneNumber = value;
                      });
                    },
                    obscureText: false,
                    textInputType: TextInputType.phone,
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  const TextTranslated('Жалоба или предложение',
                      style: AppTextStyle.editProfileText),
                  SizedBox(
                    height: 5.h,
                  ),
                  CustomTextField(
                    controller: complaintController,
                    errorText: '"Жалоба или предложение"',
                    inputFormatters: 300,
                    maxLines: 6,
                    title: 'Введите текст',
                    onChanged: (value) {
                      setState(() {
                        widget.question.question = value;
                      });
                    },
                    obscureText: false,
                    textInputType: TextInputType.text,
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  BlocConsumer<QuestionBloc, QuestionState>(
                    listener: (context, state) {
                      if (state.isLoading) {
                        setState(() {
                          spinkit;
                        });
                      }
                    },
                    builder: (context, state) {
                      return CustomButton(
                          isLoading: state.isLoading,
                          title: 'Отправить',
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            context.read<QuestionBloc>().add(
                                QuestionCreateEvent(question: widget.question));
                            if (state.isSuccess) {
                              isLoading == false;
                              showMessage(context, ["Успешно отправоено"],
                                  EnumStatusMessage.success);
                              context.router.maybePop();
                            }
                          },
                          borderRadius: 20);
                    },
                  ),
                  SizedBox(
                    height: 20.h,
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
