import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/about_us_payload.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/widgets/utils/message_show.dart';

import 'package:optombai/data/models/account/user/user.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage(name: 'AboutUsEditRoute')
class AboutUsEdit extends StatefulWidget {
  const AboutUsEdit({super.key, required this.user});
  final User user;

  @override
  State<AboutUsEdit> createState() => _AboutUsEditState();
}

class _AboutUsEditState extends State<AboutUsEdit> {
  final _formKey = GlobalKey<FormState>();
  late User user;

  final aboutController = TextEditingController();

  String supplierKind = "distributor";
  bool hasStock = false;
  final minWholesaleOrder = TextEditingController();
  bool dropshipping = false;

  String manufacturerSegment = "clothing";
  final employeesCount = TextEditingController();

  final sizeGrid = TextEditingController();
  final minOrderUnits = TextEditingController();

  String productionType = "factory";
  final moq = TextEditingController();
  bool whiteLabel = false;
  bool certification = false;

  bool officialWork = false;
  bool exportRf = false;
  bool exportEu = false;
  bool qualityGuarantee = false;

  @override
  void initState() {
    super.initState();
    user = User.copyWith(widget.user);
    aboutController.text = user.about_us;

    final data = user.about_us_data ?? {};
    manufacturerSegment = user.manufacturer_segment ?? "clothing";

    employeesCount.text = "${data["employees_count"] ?? ""}";
    sizeGrid.text = "${data["size_grid"] ?? ""}";
    minOrderUnits.text = "${data["min_order_units"] ?? ""}";
    moq.text = "${data["moq"] ?? ""}";
    minWholesaleOrder.text = "${data["min_wholesale_order"] ?? ""}";

    supplierKind = (data["supplier_kind"] ?? "distributor").toString();
    productionType = (data["production_type"] ?? "factory").toString();

    hasStock = data["has_stock"] == true;
    dropshipping = data["dropshipping"] == true;
    whiteLabel = data["white_label"] == true;
    certification = data["certification"] == true;

    officialWork = data["official_work"] == true;
    exportRf = data["export_docs_rf"] == true;
    exportEu = data["export_docs_eu"] == true;
    qualityGuarantee = data["quality_guarantee"] == true;
  }

  @override
  void dispose() {
    aboutController.dispose();
    minWholesaleOrder.dispose();
    employeesCount.dispose();
    sizeGrid.dispose();
    minOrderUnits.dispose();
    moq.dispose();
    super.dispose();
  }

  int _toInt(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    user.about_us = aboutController.text;

    Map<String, dynamic> form = {};
    final userType = user.userType ?? "";

    if (userType == "4") {
      form = {
        "supplier_kind": supplierKind,
        "has_stock": hasStock,
        "min_wholesale_order": _toInt(minWholesaleOrder),
        "dropshipping": dropshipping,
        "official_work": officialWork,
        "export_docs_rf": exportRf,
        "export_docs_eu": exportEu,
        "quality_guarantee": qualityGuarantee,
      };
    }

    if (userType == "8") {
      if (manufacturerSegment == "clothing") {
        form = {
          "employees_count": _toInt(employeesCount),
          "size_grid": sizeGrid.text.trim(),
          "min_order_units": _toInt(minOrderUnits),
          "official_work": officialWork,
          "export_docs_rf": exportRf,
          "export_docs_eu": exportEu,
          "quality_guarantee": qualityGuarantee,
        };
      } else {
        form = {
          "production_type": productionType,
          "employees_count": _toInt(employeesCount),
          "moq": _toInt(moq),
          "white_label": whiteLabel,
          "certification": certification,
          "official_work": officialWork,
          "export_docs_rf": exportRf,
          "export_docs_eu": exportEu,
          "quality_guarantee": qualityGuarantee,
        };
      }
    }

    final aboutPayload = buildAboutUsDataPayload(
      userType: userType,
      manufacturerSegment: manufacturerSegment,
      form: form,
    );

    final map = user.toJsonAdd()..addAll(aboutPayload);

    context.read<UserBloc>().add(UserUpdateEvent(id: user.id, map: map));

    showMessage(context, ["Сохранено"], EnumStatusMessage.success);
    context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final userType = user.userType ?? "";

    final bg = isDark ? const Color(0xff101A29) : const Color(0xffEDF3FF);
    final inner = isDark ? const Color(0xff0E1E33) : Colors.white;
    final label = isDark ? const Color(0xffAEB7C6) : const Color(0xff7F7F7F);

    final ddBg = isDark ? const Color(0xff0E1E33) : Colors.white;
    final ddText =
        isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87;
    final ddIcon = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const TextTranslated(
          "О нас",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DescriptionSection(
                  bg: bg,
                  inner: inner,
                  label: label,
                  isDark: isDark,
                  controller: aboutController,
                  onChanged: (v) => user.about_us = v,
                ),
                SizedBox(height: 14.h),
                if (userType == "4")
                  _SupplierSection(
                    bg: bg,
                    inner: inner,
                    label: label,
                    ddBg: ddBg,
                    ddText: ddText,
                    ddIcon: ddIcon,
                    isDark: isDark,
                    supplierKind: supplierKind,
                    hasStock: hasStock,
                    minWholesaleOrder: minWholesaleOrder,
                    dropshipping: dropshipping,
                    onSupplierKindChanged: (v) =>
                        setState(() => supplierKind = v ?? "distributor"),
                    onHasStockChanged: (v) => setState(() => hasStock = v),
                    onDropshippingChanged: (v) =>
                        setState(() => dropshipping = v),
                  ),
                if (userType == "8")
                  _ManufacturerSegmentSection(
                    bg: bg,
                    inner: inner,
                    label: label,
                    ddBg: ddBg,
                    ddText: ddText,
                    ddIcon: ddIcon,
                    manufacturerSegment: manufacturerSegment,
                    onChanged: (v) =>
                        setState(() => manufacturerSegment = v ?? "clothing"),
                  ),
                if (userType == "8" && manufacturerSegment == "clothing")
                  _ManufacturerClothingSection(
                    bg: bg,
                    inner: inner,
                    label: label,
                    employeesCount: employeesCount,
                    sizeGrid: sizeGrid,
                    minOrderUnits: minOrderUnits,
                  ),
                SizedBox(height: 14.h),
                if (userType == "8" && manufacturerSegment == "other")
                  _ManufacturerOtherSection(
                    bg: bg,
                    inner: inner,
                    label: label,
                    ddBg: ddBg,
                    ddText: ddText,
                    ddIcon: ddIcon,
                    productionType: productionType,
                    employeesCount: employeesCount,
                    moq: moq,
                    whiteLabel: whiteLabel,
                    certification: certification,
                    onProductionTypeChanged: (v) =>
                        setState(() => productionType = v ?? "factory"),
                    onWhiteLabelChanged: (v) =>
                        setState(() => whiteLabel = v),
                    onCertificationChanged: (v) =>
                        setState(() => certification = v),
                  ),
                SizedBox(height: 14.h),
                _CommonSwitchesSection(
                  bg: bg,
                  inner: inner,
                  officialWork: officialWork,
                  exportRf: exportRf,
                  exportEu: exportEu,
                  qualityGuarantee: qualityGuarantee,
                  onOfficialWorkChanged: (v) =>
                      setState(() => officialWork = v),
                  onExportRfChanged: (v) => setState(() => exportRf = v),
                  onExportEuChanged: (v) => setState(() => exportEu = v),
                  onQualityGuaranteeChanged: (v) =>
                      setState(() => qualityGuarantee = v),
                ),
                SizedBox(height: 18.h),
                _SaveButton(onSave: _save),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extracted section widgets
// ---------------------------------------------------------------------------

class _DescriptionSection extends StatelessWidget {
  final Color bg;
  final Color inner;
  final Color label;
  final bool isDark;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DescriptionSection({
    required this.bg,
    required this.inner,
    required this.label,
    required this.isDark,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      bg: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopLabel(text: "Описание компании", color: label),
          SizedBox(height: 8.h),
          _DescriptionTextField(
            controller: controller,
            inner: inner,
            isDark: isDark,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DescriptionTextField extends StatelessWidget {
  final TextEditingController controller;
  final Color inner;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _DescriptionTextField({
    required this.controller,
    required this.inner,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? const Color(0xff1A2A42) : const Color(0xffCFDEFB);
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: inner,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 5,
        minLines: 4,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Введите текст",
          hintStyle: TextStyle(color: hintColor),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _SupplierSection extends StatelessWidget {
  final Color bg;
  final Color inner;
  final Color label;
  final Color ddBg;
  final Color ddText;
  final Color ddIcon;
  final bool isDark;
  final String supplierKind;
  final bool hasStock;
  final TextEditingController minWholesaleOrder;
  final bool dropshipping;
  final ValueChanged<String?> onSupplierKindChanged;
  final ValueChanged<bool> onHasStockChanged;
  final ValueChanged<bool> onDropshippingChanged;

  const _SupplierSection({
    required this.bg,
    required this.inner,
    required this.label,
    required this.ddBg,
    required this.ddText,
    required this.ddIcon,
    required this.isDark,
    required this.supplierKind,
    required this.hasStock,
    required this.minWholesaleOrder,
    required this.dropshipping,
    required this.onSupplierKindChanged,
    required this.onHasStockChanged,
    required this.onDropshippingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      bg: bg,
      title: "📦 О поставщике",
      child: Column(
        children: [
          _LabeledWrap(
            labelText: "Вы являетесь",
            labelColor: label,
            inner: inner,
            child: DropdownButtonFormField<String>(
              dropdownColor: ddBg,
              value: supplierKind,
              style: TextStyle(color: ddText, fontWeight: FontWeight.w500),
              iconEnabledColor: ddIcon,
              items: [
                DropdownMenuItem(
                  value: "wholesaler",
                  child: Text("Оптовый поставщик",
                      style: TextStyle(color: ddText)),
                ),
                DropdownMenuItem(
                  value: "distributor",
                  child:
                      Text("Дистрибьютор", style: TextStyle(color: ddText)),
                ),
                DropdownMenuItem(
                  value: "reseller",
                  child:
                      Text("Перекупщик", style: TextStyle(color: ddText)),
                ),
              ],
              onChanged: onSupplierKindChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          _SwitchTileCard(
            inner: inner,
            title: "Есть склад в наличии",
            value: hasStock,
            onChanged: onHasStockChanged,
          ),
          SizedBox(height: 10.h),
          _LabeledWrap(
            labelText: "Минимальный опт. заказ",
            labelColor: label,
            inner: inner,
            child: _PlainInput(
              controller: minWholesaleOrder,
              keyboardType: TextInputType.number,
              hint: "Например: 100",
              isDark: isDark,
            ),
          ),
          SizedBox(height: 10.h),
          _SwitchTileCard(
            inner: inner,
            title: "Возможна работа по дропшиппингу",
            value: dropshipping,
            onChanged: onDropshippingChanged,
          ),
        ],
      ),
    );
  }
}

class _ManufacturerSegmentSection extends StatelessWidget {
  final Color bg;
  final Color inner;
  final Color label;
  final Color ddBg;
  final Color ddText;
  final Color ddIcon;
  final String manufacturerSegment;
  final ValueChanged<String?> onChanged;

  const _ManufacturerSegmentSection({
    required this.bg,
    required this.inner,
    required this.label,
    required this.ddBg,
    required this.ddText,
    required this.ddIcon,
    required this.manufacturerSegment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      bg: bg,
      title: "🏭 Тип производителя",
      child: _LabeledWrap(
        labelText: "Сегмент",
        labelColor: label,
        inner: inner,
        child: DropdownButtonFormField<String>(
          dropdownColor: ddBg,
          value: manufacturerSegment,
          style: TextStyle(color: ddText, fontWeight: FontWeight.w500),
          iconEnabledColor: ddIcon,
          items: [
            DropdownMenuItem(
              value: "clothing",
              child: Text("Производитель одежды",
                  style: TextStyle(color: ddText)),
            ),
            DropdownMenuItem(
              value: "other",
              child: Text(
                "Производитель (другие категории)",
                style: TextStyle(fontSize: 12, color: ddText),
              ),
            ),
          ],
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

class _ManufacturerClothingSection extends StatelessWidget {
  final Color bg;
  final Color inner;
  final Color label;
  final TextEditingController employeesCount;
  final TextEditingController sizeGrid;
  final TextEditingController minOrderUnits;

  const _ManufacturerClothingSection({
    required this.bg,
    required this.inner,
    required this.label,
    required this.employeesCount,
    required this.sizeGrid,
    required this.minOrderUnits,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      bg: bg,
      title: "🏭 О производителе одежды",
      child: Column(
        children: [
          _LabeledWrap(
            labelText: "Количество сотрудников",
            labelColor: label,
            inner: inner,
            child: CustomTextField(
              initValue: employeesCount.text,
              onChanged: (v) => employeesCount.text = v,
              obscureText: false,
              textInputType: TextInputType.number,
              inputFormatters: 10,
              maxLines: 1,
              filledOverride: true,
              fillColorLight: Colors.white,
              fillColorDark: const Color(0xff0E1E33),
            ),
          ),
          SizedBox(height: 10.h),
          _LabeledWrap(
            labelText: "Размерная сетка",
            labelColor: label,
            inner: inner,
            child: CustomTextField(
              initValue: sizeGrid.text,
              onChanged: (v) => sizeGrid.text = v,
              obscureText: false,
              textInputType: TextInputType.text,
              inputFormatters: 50,
              maxLines: 1,
              filledOverride: true,
              fillColorLight: Colors.white,
              fillColorDark: const Color(0xff0E1E33),
            ),
          ),
          SizedBox(height: 10.h),
          _LabeledWrap(
            labelText: "Минимальный заказ (в единицах)",
            labelColor: label,
            inner: inner,
            child: CustomTextField(
              initValue: minOrderUnits.text,
              onChanged: (v) => minOrderUnits.text = v,
              obscureText: false,
              textInputType: TextInputType.number,
              inputFormatters: 20,
              maxLines: 1,
              filledOverride: true,
              fillColorLight: Colors.white,
              fillColorDark: const Color(0xff0E1E33),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManufacturerOtherSection extends StatelessWidget {
  final Color bg;
  final Color inner;
  final Color label;
  final Color ddBg;
  final Color ddText;
  final Color ddIcon;
  final String productionType;
  final TextEditingController employeesCount;
  final TextEditingController moq;
  final bool whiteLabel;
  final bool certification;
  final ValueChanged<String?> onProductionTypeChanged;
  final ValueChanged<bool> onWhiteLabelChanged;
  final ValueChanged<bool> onCertificationChanged;

  const _ManufacturerOtherSection({
    required this.bg,
    required this.inner,
    required this.label,
    required this.ddBg,
    required this.ddText,
    required this.ddIcon,
    required this.productionType,
    required this.employeesCount,
    required this.moq,
    required this.whiteLabel,
    required this.certification,
    required this.onProductionTypeChanged,
    required this.onWhiteLabelChanged,
    required this.onCertificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      bg: bg,
      title: "🏭 О производителе (другие категории)",
      child: Column(
        children: [
          _LabeledWrap(
            labelText: "Тип производства",
            labelColor: label,
            inner: inner,
            child: DropdownButtonFormField<String>(
              dropdownColor: ddBg,
              value: productionType,
              style: TextStyle(color: ddText, fontWeight: FontWeight.w500),
              iconEnabledColor: ddIcon,
              items: [
                DropdownMenuItem(
                  value: "factory",
                  child:
                      Text("Фабрика", style: TextStyle(color: ddText)),
                ),
                DropdownMenuItem(
                  value: "workshop",
                  child: Text("Цех", style: TextStyle(color: ddText)),
                ),
                DropdownMenuItem(
                  value: "atelier",
                  child:
                      Text("Мастерская", style: TextStyle(color: ddText)),
                ),
              ],
              onChanged: onProductionTypeChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          _LabeledWrap(
            labelText: "Количество сотрудников",
            labelColor: label,
            inner: inner,
            child: CustomTextField(
              initValue: employeesCount.text,
              onChanged: (v) => employeesCount.text = v,
              obscureText: false,
              textInputType: TextInputType.number,
              inputFormatters: 10,
              maxLines: 1,
              filledOverride: true,
              fillColorLight: Colors.white,
              fillColorDark: const Color(0xff0E1E33),
            ),
          ),
          SizedBox(height: 10.h),
          _LabeledWrap(
            labelText: "Минимальный заказ (MOQ)",
            labelColor: label,
            inner: inner,
            child: CustomTextField(
              initValue: moq.text,
              onChanged: (v) => moq.text = v,
              obscureText: false,
              textInputType: TextInputType.number,
              inputFormatters: 20,
              maxLines: 1,
              filledOverride: true,
              fillColorLight: Colors.white,
              fillColorDark: const Color(0xff0E1E33),
            ),
          ),
          SizedBox(height: 10.h),
          _SwitchTileCard(
            inner: inner,
            title: "Работаете ли под брендом заказчика?",
            value: whiteLabel,
            onChanged: onWhiteLabelChanged,
          ),
          SizedBox(height: 10.h),
          _SwitchTileCard(
            inner: inner,
            title: "Есть ли сертификация продукции?",
            value: certification,
            onChanged: onCertificationChanged,
          ),
        ],
      ),
    );
  }
}

class _CommonSwitchesSection extends StatelessWidget {
  final Color bg;
  final Color inner;
  final bool officialWork;
  final bool exportRf;
  final bool exportEu;
  final bool qualityGuarantee;
  final ValueChanged<bool> onOfficialWorkChanged;
  final ValueChanged<bool> onExportRfChanged;
  final ValueChanged<bool> onExportEuChanged;
  final ValueChanged<bool> onQualityGuaranteeChanged;

  const _CommonSwitchesSection({
    required this.bg,
    required this.inner,
    required this.officialWork,
    required this.exportRf,
    required this.exportEu,
    required this.qualityGuarantee,
    required this.onOfficialWorkChanged,
    required this.onExportRfChanged,
    required this.onExportEuChanged,
    required this.onQualityGuaranteeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      bg: bg,
      title: "✅ Общие условия",
      child: Column(
        children: [
          _SwitchTileCard(
            inner: inner,
            title: "Работаете ли официально (в белую)?",
            value: officialWork,
            onChanged: onOfficialWorkChanged,
          ),
          SizedBox(height: 10.h),
          _SwitchTileCard(
            inner: inner,
            title: "Есть документы для экспорта в РФ?",
            value: exportRf,
            onChanged: onExportRfChanged,
          ),
          SizedBox(height: 10.h),
          _SwitchTileCard(
            inner: inner,
            title: "Есть документы для экспорта в Европу?",
            value: exportEu,
            onChanged: onExportEuChanged,
          ),
          SizedBox(height: 10.h),
          _SwitchTileCard(
            inner: inner,
            title: "Гарантия качества / возврат брака?",
            value: qualityGuarantee,
            onChanged: onQualityGuaranteeChanged,
          ),
        ],
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
          showMessage(context, ["Сохранено"], EnumStatusMessage.success);
        }
      },
      builder: (context, state) {
        return CustomButton(
          title: "Сохранить",
          onPressed: onSave,
          borderRadius: 20,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building-block widgets
// ---------------------------------------------------------------------------

class _TopLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _TopLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextTranslated(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: color,
      ),
    );
  }
}

class _LabeledWrap extends StatelessWidget {
  final String labelText;
  final Color labelColor;
  final Color inner;
  final Widget child;

  const _LabeledWrap({
    required this.labelText,
    required this.labelColor,
    required this.inner,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopLabel(text: labelText, color: labelColor),
        SizedBox(height: 6.h),
        _FieldWrap(inner: inner, child: child),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color bg;
  final String? title;
  final Widget child;

  const _SectionCard({
    required this.bg,
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: bg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            TextTranslated(
              title!,
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: titleColor),
            ),
            SizedBox(height: 12.h),
          ],
          child,
        ],
      ),
    );
  }
}

class _FieldWrap extends StatelessWidget {
  final Color inner;
  final Widget child;

  const _FieldWrap({required this.inner, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final border =
        isDark ? const Color(0xff1A2A42) : const Color(0xffCFDEFB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: inner,
        border: Border.all(color: border, width: 1),
      ),
      child: child,
    );
  }
}

class _SwitchTileCard extends StatelessWidget {
  final Color inner;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTileCard({
    required this.inner,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    const active = Color(0xff3B82F6);
    final inactive =
        isDark ? const Color(0xff24354E) : const Color(0xffDDE7FF);
    final border =
        isDark ? const Color(0xff1A2A42) : const Color(0xffCFDEFB);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: inner,
        border: Border.all(color: border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.92)
                    : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Transform.scale(
            scale: 0.95,
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: active,
              inactiveTrackColor: inactive,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainInput extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? hint;
  final bool isDark;

  const _PlainInput({
    required this.controller,
    required this.keyboardType,
    required this.isDark,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
