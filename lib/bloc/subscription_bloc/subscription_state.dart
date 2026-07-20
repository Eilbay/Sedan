import 'package:optombai/data/models/subscription/subscription_plan_model.dart';
import 'package:equatable/equatable.dart';

class SubscriptionState extends Equatable {
  final List<SubscriptionPlan> plans;

  const SubscriptionState({
    this.plans = const [],
  });

  copyWith({
    List<SubscriptionPlan> plans = const [],
  }) {
    return SubscriptionState(
      plans: plans,
    );
  }

  @override
  List<Object?> get props => [plans];
}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  const SubscriptionLoaded({required super.plans});

  @override
  List<Object> get props => [plans.map((plan) => plan.title).toList()];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError({required this.message});
  @override
  List<Object> get props => [message];
}
