import 'package:equatable/equatable.dart';

sealed class CountryEvent extends Equatable {
  const CountryEvent();
}

class CountryAllEvent extends CountryEvent {
  final bool forceRefresh;

  const CountryAllEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}