import 'package:equatable/equatable.dart';

class CountryModel extends Equatable {
  final int? id;
  final String name;
  final String? iso2;
  final String? flag;
  final String? circle_flag;
  final String? square_flag;

  const CountryModel({
    this.id,
    this.name = "",
    this.iso2,
    this.flag,
    this.circle_flag,
    this.square_flag,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'],
      name: json['title'] ?? "",
      iso2: json['iso2'],
      flag: json['flag'],
      circle_flag: json['circle_flag'],
      square_flag: json['square_flag'],
    );
  }

  CountryModel copyWith({
    int? id,
    String? name,
    String? iso2,
    String? flag,
    String? circle_flag,
    String? square_flag,
  }) {
    return CountryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iso2: iso2 ?? this.iso2,
      flag: flag ?? this.flag,
      circle_flag: circle_flag ?? this.circle_flag,
      square_flag: square_flag ?? this.square_flag,
    );
  }

  @override
  List<Object?> get props => [id, name, iso2, flag, circle_flag, square_flag];
}
