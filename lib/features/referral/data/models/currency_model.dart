class CurrencyModel {
  const CurrencyModel({
    required this.id,
    required this.flag,
    required this.name,
    required this.circleFlag,
    required this.squareFlag,
    required this.price,
  });

  final int id;
  final String flag;
  final String name;
  final String circleFlag;
  final String squareFlag;
  final String price;

  factory CurrencyModel.fromJson(Map<String, dynamic> map) {
    return CurrencyModel(
      id: map['id'] as int,
      flag: map['flag'] as String,
      name: map['name'] as String,
      circleFlag: map['circle_flag'] as String,
      squareFlag: map['square_flag'] as String,
      price: map['price'] as String,
    );
  }
}
