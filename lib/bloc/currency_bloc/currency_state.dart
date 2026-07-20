part of 'currency_bloc.dart';

class CurrencyState extends Equatable {
  final bool isLoading;
  final List<String> errors;
  final bool isSuccess;
  final List<CurrencyModel> currency;
  final CurrencyModel? selectedCurrency;

  const CurrencyState({
    this.isLoading = false,
    this.currency = const [],
    this.errors = const [],
    this.isSuccess = false,
    this.selectedCurrency,
  });

  CurrencyState copyWith({
    bool? isLoading,
    List<String>? errors,
    bool? isSuccess,
    List<CurrencyModel>? currency,
    CurrencyModel? selectedCurrency,
  }) {
    return CurrencyState(
      isLoading: isLoading ?? this.isLoading,
      currency: currency ?? this.currency,
      errors: errors ?? this.errors,
      isSuccess: isSuccess ?? this.isSuccess,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, errors, isSuccess, currency, selectedCurrency];
}
