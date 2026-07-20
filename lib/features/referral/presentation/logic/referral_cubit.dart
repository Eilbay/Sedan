import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/data/models/currency/currency_model.dart';
import 'package:optombai/features/referral/data/models/referral_invitee_model.dart';
import 'package:optombai/features/referral/data/models/referral_profile_model.dart';
import 'package:optombai/features/referral/data/models/referral_transaction_model.dart';
import 'package:optombai/features/referral/data/models/referral_wallet_model.dart';
import 'package:optombai/features/referral/data/models/referral_withdrawal_model.dart';
import 'package:optombai/features/referral/domain/repository/referral_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'referral_state.dart';

class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit({required ReferralRepository repository, required this.preferences})
      : _repository = repository,
        super(const ReferralState());

  final SharedPreferences preferences;
  final ReferralRepository _repository;

  String _getToken() => preferences.getString(TOKEN_KEY) ?? '';

  Future<void> load() async {
    if (_getToken().isEmpty) return;

    emit(
      state.copyWith(status: FetchStatus.loading, errorMessage: null),
    );

    try {
      final profileFuture = _repository.getMyProfile();
      final walletFuture = _repository.getMyWallet();
      final inviteesFuture = _repository.getMyInvitees();
      final transactionsFuture = _repository.getMyTransactions();
      final withdrawalsFuture = _repository.getMyWithdrawals();
      final currenciesFuture = _repository.getCurrencies();

      final results = await Future.wait([
        profileFuture,
        walletFuture,
        inviteesFuture,
        transactionsFuture,
        withdrawalsFuture,
        currenciesFuture,
      ]);

      emit(
        state.copyWith(
          status: FetchStatus.success,
          profile: results[0] as ReferralProfileModel,
          wallet: results[1] as ReferralWalletModel,
          invitees: results[2] as List<ReferralInviteeModel>,
          transactions: results[3] as List<ReferralTransactionModel>,
          withdrawals: results[4] as List<ReferralWithdrawalModel>,
          currencies: results[5] as List<CurrencyModel>,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FetchStatus.error,
          errorMessage: 'Не удалось загрузить реферальные данные',
        ),
      );
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<bool?> createWithdrawal({
    required String amount,
    required String user,
    required String details,
    required String comment,
    required String fullName,
    required String currency,
    XFile? qrFile,
  }) async {
    emit(state.copyWith(status: FetchStatus.loading));

    try {
      await _repository.createWithdrawal(
        amount: amount,
        user: user,
        details: details,
        comment: comment,
        fullName: fullName,
        qrFile: qrFile,
        currency: currency,
      );

      final wallet = await _repository.getMyWallet();
      final withdrawals = await _repository.getMyWithdrawals();

      emit(state.copyWith(status: FetchStatus.success, wallet: wallet, withdrawals: withdrawals));

      return true;
    } catch (_) {
      emit(state.copyWith(status: FetchStatus.error, errorMessage: 'Не удалось создать вывод'));

      return false;
    }
  }
}
