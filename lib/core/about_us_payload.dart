Map<String, dynamic> buildAboutUsDataPayload({
  required String userType,
  String? manufacturerSegment,
  required Map<String, dynamic> form,
}) {
  final seg = normalizeManufacturerSegment(manufacturerSegment);

  final base = <String, dynamic>{
    "manufacturer_segment": seg,
  };

  if (userType == "4") {
    return {
      ...base,
      "about_us_data": {
        "supplier_kind": form["supplier_kind"],
        "has_stock": form["has_stock"] ?? false,
        "min_wholesale_order": form["min_wholesale_order"] ?? 0,
        "dropshipping": form["dropshipping"] ?? false,
        "official_work": form["official_work"] ?? false,
        "export_docs_rf": form["export_docs_rf"] ?? false,
        "export_docs_eu": form["export_docs_eu"] ?? false,
        "quality_guarantee": form["quality_guarantee"] ?? false,
      }
    };
  }

  if (userType == "8") {
    if (seg == "clothing") {
      return {
        ...base,
        "about_us_data": {
          "employees_count": form["employees_count"] ?? 0,
          "size_grid": form["size_grid"] ?? "",
          "min_order_units": form["min_order_units"] ?? 0,
          "official_work": form["official_work"] ?? false,
          "export_docs_rf": form["export_docs_rf"] ?? false,
          "export_docs_eu": form["export_docs_eu"] ?? false,
          "quality_guarantee": form["quality_guarantee"] ?? false,
        }
      };
    }

    return {
      ...base,
      "about_us_data": {
        "production_type": form["production_type"],
        "employees_count": form["employees_count"] ?? 0,
        "moq": form["moq"] ?? 0,
        "white_label": form["white_label"] ?? false,
        "certification": form["certification"] ?? false,
        "official_work": form["official_work"] ?? false,
        "export_docs_rf": form["export_docs_rf"] ?? false,
        "export_docs_eu": form["export_docs_eu"] ?? false,
        "quality_guarantee": form["quality_guarantee"] ?? false,
      }
    };
  }

  return base;
}

String normalizeManufacturerSegment(String? v) {
  final s = (v ?? '').trim().toLowerCase();
  return (s == 'clothing' || s == 'other') ? s : 'other';
}
