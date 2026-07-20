part of 'currency_bloc.dart';

sealed class CurrencyEvent extends Equatable {}

class CurrencyAllEvent extends CurrencyEvent {
  final bool forceRefresh;

  CurrencyAllEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SetSelectedCurrencyEvent extends CurrencyEvent {
  final CurrencyModel selected;

  SetSelectedCurrencyEvent(this.selected);

  @override
  List<Object?> get props => [selected];
}
