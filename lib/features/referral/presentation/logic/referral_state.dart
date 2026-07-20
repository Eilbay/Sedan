// ignore_for_file: pulc_member_api_docs, sort_constructors_first
part of 'referral_cubit.dart';

enum FetchStatus { initial, loading, success, error }

class ReferralState {
  const ReferralState({
    this.status = FetchStatus.initial,
    this.profile,
    this.wallet,
    this.invitees = const [],
    this.transactions = const [],
    this.withdrawals = const [],
    this.currencies = const [],
    this.errorMessage,
  });

  final FetchStatus status;
  final ReferralProfileModel? profile;
  final ReferralWalletModel? wallet;
  final List<ReferralInviteeModel> invitees;
  final List<ReferralTransactionModel> transactions;
  final List<ReferralWithdrawalModel> withdrawals;
  final List<CurrencyModel> currencies;
  final String? errorMessage;

  ReferralState copyWith({
    FetchStatus? status,
    ReferralProfileModel? profile,
    ReferralWalletModel? wallet,
    List<ReferralInviteeModel>? invitees,
    List<ReferralTransactionModel>? transactions,
    List<ReferralWithdrawalModel>? withdrawals,
    List<CurrencyModel>? currencies,
    String? errorMessage,
  }) {
    return ReferralState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      wallet: wallet ?? this.wallet,
      invitees: invitees ?? this.invitees,
      transactions: transactions ?? this.transactions,
      withdrawals: withdrawals ?? this.withdrawals,
      currencies: currencies ?? this.currencies,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
