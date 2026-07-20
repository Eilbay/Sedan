import 'package:equatable/equatable.dart';

class CurrencyModel extends Equatable {
  final int id;
  final String? flag;
  final String name;
  final String? circleFlag;
  final String? squareFlag;
  final String? price;

  const CurrencyModel({
    required this.id,
    required this.name,
    this.flag,
    this.circleFlag,
    this.squareFlag,
    this.price,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: json['id'],
      name: json['name'],
      flag: json['flag'],
      circleFlag: json['circle_flag'],
      squareFlag: json['square_flag'],
      price: json['price'],
    );
  }

  CurrencyModel copyWith({
    int? id,
    String? flag,
    String? name,
    String? circleFlag,
    String? squareFlag,
    String? price,
  }) {
    return CurrencyModel(
      id: id ?? this.id,
      flag: flag ?? this.flag,
      name: name ?? this.name,
      circleFlag: circleFlag ?? this.circleFlag,
      squareFlag: squareFlag ?? this.squareFlag,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [id, flag, name, circleFlag, squareFlag, price];
}
