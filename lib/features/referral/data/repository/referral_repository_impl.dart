import 'package:optombai/core/import_links.dart';
import 'package:optombai/features/referral/data/models/referral_invitee_model.dart';
import 'package:optombai/features/referral/data/models/referral_profile_model.dart';
import 'package:optombai/features/referral/data/models/referral_transaction_model.dart';
import 'package:optombai/features/referral/data/models/referral_wallet_model.dart';
import 'package:optombai/features/referral/data/models/referral_withdrawal_model.dart';
import 'package:optombai/features/referral/domain/repository/referral_repository.dart';

import 'package:optombai/features/referral/data/data_sources/referral_remote_data_source.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  ReferralRepositoryImpl(this._remote);

  final ReferralRemoteDataSource _remote;

  @override
  Future<ReferralProfileModel> getMyProfile() {
    return _remote.getMyProfile();
  }

  @override
  Future<ReferralWalletModel> getMyWallet() {
    return _remote.getMyWallet();
  }

  @override
  Future<List<ReferralInviteeModel>?> getMyInvitees() {
    return _remote.getMyInvitees();
  }

  @override
  Future<List<ReferralTransactionModel>> getMyTransactions() {
    return _remote.getMyTransactions();
  }

  @override
  Future<List<ReferralWithdrawalModel>> getMyWithdrawals() {
    return _remote.getMyWithdrawals();
  }

  @override
  Future<List<CurrencyModel>> getCurrencies() {
    return _remote.getCurrencies();
  }

  @override
  Future<ReferralWithdrawalModel> createWithdrawal({
    required String amount,
    required String user,
    required String details,
    required String comment,
    required String fullName,
    required String currency,
    XFile? qrFile,
  }) {
    return _remote.createWithdrawal(
      amount: amount,
      user: user,
      details: details,
      comment: comment,
      fullName: fullName,
      qrFile: qrFile,
      currency: currency,
    );
  }
}
