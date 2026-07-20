class ModelValidation {
  final bool isGood;
  final String? errorCode;
  final List<String>? goodClothesTypes;
  final String? message;

  ModelValidation(
      {required this.isGood,
      this.errorCode,
      this.goodClothesTypes,
      this.message});

  factory ModelValidation.fromJson(Map<String, dynamic> j) => ModelValidation(
        isGood: j['is_good'] as bool,
        errorCode: j['error_code'] as String?,
        goodClothesTypes: (j['good_clothes_types'] as List?)?.cast<String>(),
        message: j['message'] as String?,
      );
}
