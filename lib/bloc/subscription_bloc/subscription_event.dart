import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchSubscriptionEvent extends SubscriptionEvent {}
