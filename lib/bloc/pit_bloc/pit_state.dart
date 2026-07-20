import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/pit/pit_model.dart';

class PitState extends Equatable {
  final bool isLoading;
  final bool isProcessing;
  final List<String> errors;
  final bool isSuccess;
  final bool isIAPSuccess;
  final double balance;
  final PitModel? wallet;
  final PitInitResponse? pitResponse;
  final IAPPitResponse? iapPitResponse;

  const PitState({
    this.isLoading = false,
    this.isProcessing = false,
    this.errors = const [],
    this.isSuccess = false,
    this.isIAPSuccess = false,
    this.balance = 0.0,
    this.wallet,
    this.pitResponse,
    this.iapPitResponse,
  });

  PitState copyWith({
    bool? isLoading,
    bool? isProcessing,
    List<String>? errors,
    bool? isSuccess,
    bool? isIAPSuccess,
    double? balance,
    PitModel? wallet,
    PitInitResponse? pitResponse,
    IAPPitResponse? iapPitResponse,
  }) {
    return PitState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errors: errors ?? this.errors,
      isSuccess: isSuccess ?? this.isSuccess,
      isIAPSuccess: isIAPSuccess ?? this.isIAPSuccess,
      balance: balance ?? this.balance,
      wallet: wallet ?? this.wallet,
      pitResponse: pitResponse ?? this.pitResponse,
      iapPitResponse: iapPitResponse ?? this.iapPitResponse,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isProcessing,
        errors,
        isSuccess,
        isIAPSuccess,
        balance,
        wallet,
        pitResponse,
        iapPitResponse,
      ];
}
