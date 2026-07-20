import 'package:equatable/equatable.dart';

abstract class PitEvent extends Equatable {
  const PitEvent();

  @override
  List<Object?> get props => [];
}

/// Load current wallet balance
class LoadPitEvent extends PitEvent {
  const LoadPitEvent();
}

/// Initialize top-up pmt
class InitPitEvent extends PitEvent {
  final double amount;
  final String provider; // "finik" or "freedompay"
  final String currency;

  const InitPitEvent({
    required this.amount,
    required this.provider,
    this.currency = 'KGS',
  });

  @override
  List<Object?> get props => [amount, provider, currency];
}

/// Reset state
class ResetPitStateEvent extends PitEvent {
  const ResetPitStateEvent();
}

/// Top up via IAP (In-App Purchase)
class IAPPitEvent extends PitEvent {
  final String receiptData;
  final String productId;
  final String platform;
  final String transactionId;

  const IAPPitEvent({
    required this.receiptData,
    required this.productId,
    required this.platform,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [receiptData, productId, platform, transactionId];
}
