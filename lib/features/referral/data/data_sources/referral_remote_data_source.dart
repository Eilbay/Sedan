import 'package:dio/dio.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/repositories/user_repository.dart';
import 'package:optombai/features/referral/data/models/referral_invitee_model.dart';
import 'package:optombai/features/referral/data/models/referral_profile_model.dart';
import 'package:optombai/features/referral/data/models/referral_transaction_model.dart';
import 'package:optombai/features/referral/data/models/referral_wallet_model.dart';
import 'package:optombai/features/referral/data/models/referral_withdrawal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralRemoteDataSource {
  ReferralRemoteDataSource(this._dio, this.preferences);

  final Dio _dio;
  final SharedPreferences preferences;

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  Options headers() => Options(
        headers: {
          'Authorization': 'Bearer ${getToken()}',
          'Content-Type': 'application/json',
        },
      );

  Future<ReferralProfileModel> getMyProfile() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.referralMyProfile,
        options: headers(),
      );

      return ReferralProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<ReferralWalletModel> getMyWallet() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.referralMyWallet,
        options: headers(),
      );

      return ReferralWalletModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<ReferralInviteeModel>?> getMyInvitees() async {
    try {
      final List<ReferralInviteeModel> invitees = [];
      final res = await _dio.get(
        ApiEndpoints.referralMyInvitees,
        options: headers(),
      );

      final data = res.data['results'] as List<dynamic>;
      for (var e in data) {
        final invite = ReferralInviteeModel.fromJson(e as Map<String, dynamic>);

        final user = await getUser(invite.user);

        invitees.add(invite.copyWith(
          userName: user.username,
          userCountry: user.country?.square_flag,
        ));
      }
      return invitees;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<User> getUser(String id) async {
    try {
      final response = await _dio.get(
        '$endpointApi/$id/',
        options: headers(),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<ReferralTransactionModel>> getMyTransactions() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.referralMyTransactions,
        options: headers(),
      );

      final data = res.data['results'] as List<dynamic>;
      return data.map((e) => ReferralTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<ReferralWithdrawalModel>> getMyWithdrawals() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.referralMyWithdrawals,
        options: headers(),
      );

      final data = res.data['results'] as List<dynamic>;
      return data.map((e) => ReferralWithdrawalModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<CurrencyModel>> getCurrencies() async {
    try {
      final res = await _dio.get(
        ApiEndpoints.currencies,
        options: headers(),
      );

      final List<dynamic> data = res.data as List<dynamic>;

      return data.map((e) => CurrencyModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<ReferralWithdrawalModel> createWithdrawal({
    required String amount,
    required String user,
    required String currency,
    String? fullName,
    String? details,
    String? comment,
    XFile? qrFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'amount': amount,
        'user': user,
        if (details != null) 'details': details,
        if (fullName != null) 'full_name': fullName,
        if (comment != null) 'bank_name': comment,
        'currency': currency,
        if (qrFile != null)
          'qr_code': await MultipartFile.fromFile(
            qrFile.path,
            filename: qrFile.name,
          ),
      });

      final res = await _dio.post(ApiEndpoints.referralMyWithdrawals, data: formData, options: headers());

      return ReferralWithdrawalModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
