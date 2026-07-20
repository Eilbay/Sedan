import 'package:optombai/core/import_links.dart';
import 'package:optombai/features/referral/data/models/referral_invitee_model.dart';
import 'package:optombai/features/referral/data/models/referral_profile_model.dart';
import 'package:optombai/features/referral/data/models/referral_transaction_model.dart';
import 'package:optombai/features/referral/data/models/referral_wallet_model.dart';
import 'package:optombai/features/referral/data/models/referral_withdrawal_model.dart';

abstract class ReferralRepository {
  Future<ReferralProfileModel> getMyProfile();
  Future<ReferralWalletModel> getMyWallet();
  Future<List<ReferralInviteeModel>?> getMyInvitees();
  Future<List<ReferralTransactionModel>> getMyTransactions();
  Future<List<ReferralWithdrawalModel>> getMyWithdrawals();
  Future<List<CurrencyModel>> getCurrencies();
  Future<ReferralWithdrawalModel> createWithdrawal({
    required String amount,
    required String user,
    required String details,
    required String comment,
    required String fullName,
    XFile? qrFile,
    required String currency,
  });
}
