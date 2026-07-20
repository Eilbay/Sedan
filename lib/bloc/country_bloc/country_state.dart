import 'package:optombai/data/models/countries/countries.dart';
import 'package:equatable/equatable.dart';

class CountryState extends Equatable {
  final bool isLoading;
  final List<String> errors;
  final bool isSuccess;
  final List<CountryModel> list;

  const CountryState({
    this.list = const [],
    this.isLoading = false,
    this.errors = const [],
    this.isSuccess = false,
  });

  copyWith({
    bool isLoading = false,
    List<String> errors = const [],
    bool isSuccess = false,
    List<CountryModel>? list,
  }) {
    return CountryState(
      list: list ?? this.list,
      isLoading: isLoading,
      errors: errors,
      isSuccess: isSuccess,
    );
  }

  @override
  List<Object?> get props => [list, isSuccess, isLoading, errors];
}
