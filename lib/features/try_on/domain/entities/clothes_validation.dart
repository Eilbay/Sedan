class ClothesValidation {
  final bool isClothes;
  final String? clothesType;
  final String? message;
  final String? error;

  ClothesValidation({
    required this.isClothes,
    this.clothesType,
    this.message,
    this.error,
  });

  factory ClothesValidation.fromJson(Map<String, dynamic> j) =>
      ClothesValidation(
        isClothes: j['is_clothes'] as bool,
        clothesType: j['clothes_type'] as String?,
        message: j['message'] as String?,
        error: j['error'] as String?,
      );
}
