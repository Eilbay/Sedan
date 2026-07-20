import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/question_bloc/question_bloc.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/question/question_model.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final QuestionModel _question = QuestionModel();

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    return CustomScaffold(
      title: "Сообщить о проблеме",
      leading: IconButton(
        onPressed: () => context.router.maybePop(),
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      child: BlocConsumer<QuestionBloc, QuestionState>(
        listener: (context, state) {
          if (state.isSuccess) {
            showMessage(
                context, ["Успешно отправлено"], EnumStatusMessage.success);
            context.router.maybePop();
          }
          if (state.errors.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: TextTranslated(state.errors.join('\n'))),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 45),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextTranslated(
                      'Вопрос *',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      errorText: "Введите ваш вопрос",
                      title: "Введите ваш вопрос",
                      maxLines: 1,
                      inputFormatters: 256,
                      onChanged: (value) => _question.question = value,
                      obscureText: false,
                    ),
                    SizedBox(height: 20.h),
                    const TextTranslated(
                      'Ваше имя',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      title: "Введите ваше имя",
                      maxLines: 1,
                      inputFormatters: 256,
                      onChanged: (value) => _question.name = value,
                      obscureText: false,
                    ),
                    SizedBox(height: 20.h),
                    const TextTranslated(
                      'Email',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      title: "Введите ваш email",
                      maxLines: 1,
                      textInputType: TextInputType.emailAddress,
                      inputFormatters: 254,
                      isEmail: true,
                      errorText: "Адрес электронной почты",
                      onChanged: (value) => _question.email = value,
                      obscureText: false,
                    ),
                    SizedBox(height: 20.h),
                    const TextTranslated(
                      'Номер телефона',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    CustomTextField(
                      title: "Введите ваш номер телефона",
                      maxLines: 1,
                      fixedPlus: true,
                      textInputType: TextInputType.phone,
                      inputFormatters: 15,
                      isNumber: true,
                      errorText: "Номер телефона",
                      onChanged: (value) => _question.phoneNumber = value,
                      obscureText: false,
                    ),
                    SizedBox(height: 40.h),
                    ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<QuestionBloc>().add(
                                      QuestionCreateEvent(question: _question),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: state.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const TextTranslated(
                              'Отправить',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
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
