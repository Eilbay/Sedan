extension TakeBetween on String {
  String between(String start, String end) {
    final startIndex = indexOf(start);
    final endIndex = indexOf(end, startIndex + start.length);

    if (startIndex > 0 && endIndex > 0) {
      return substring(startIndex + start.length, endIndex);
    } else {
      return '';
    }
  }

  String betweenXml(String tag) {
    return between("<$tag>", "</$tag>");
  }

  int? betweenXmlInt(String tag) {
    var value = between("<$tag>", "</$tag>");
    if (value.isNotEmpty) return value.toInt();
    return 0;
  }

  double? betweenXmlDouble(String tag) {
    var value = between("<$tag>", "</$tag>");
    if (value.isNotEmpty) return double.tryParse(value);
    return 0;
  }

  int? toInt() {
    return int.tryParse(this);
  }
}
