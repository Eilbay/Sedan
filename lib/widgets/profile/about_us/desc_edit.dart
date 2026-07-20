import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';

@RoutePage()
class DescEditScreen extends StatefulWidget {
  const DescEditScreen({super.key});

  @override
  State<DescEditScreen> createState() => _DescEditScreenState();
}

class _DescEditScreenState extends State<DescEditScreen> {
  TextEditingController descController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    descController.dispose();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextTranslated(
                "Редактировать описание",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              SizedBox(
                height: 25.h,
              ),
              const TextTranslated('Описание',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
              SizedBox(height: 8.h),
              CustomTextField(
                controller: descController,
                errorText: '"Описание"',
                inputFormatters: 300,
                maxLines: 6,
                title: 'Введите текст',
                onChanged: (value) {
                  descController = value;
                },
                obscureText: false,
                textInputType: TextInputType.text,
              ),
              SizedBox(
                height: 25.h,
              ),
              CustomButton(
                title: "Сохранить",
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                },
                borderRadius: 20,
              )
            ],
          ),
        ),
      ),
    );
  }
}
