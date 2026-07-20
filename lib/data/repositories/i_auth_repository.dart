import 'package:optombai/data/models/account/token.dart';
import 'package:optombai/data/models/account/user/user_status.dart';

abstract interface class IAuthRepository {
  Future<Map<String, dynamic>> registerUser({
    String? email,
    required String password,
    required String username,
    required String phoneNumber,
    int? regionId,
    bool isEmailConfirmation = false,
    String? referralCode,
  });

  Future<String> activateAccount(String token);

  Future<Token> login(String username, String password);

  Future<String> confirmResetCodeByPhone({
    required String phoneNumber,
    required String code,
  });

  Future<String> confirmResetCodeByEmail({
    required String email,
    required String code,
  });

  Future<int> getUserCountByType(
    String userType, {
    String? categories,
  });

  Future<int> getClientCountByType(
    String userType, {
    String? categories,
  });

  Future<Token> googleAuth(String token);

  Future<void> sendResetPasswordRequest(String value, String endpoint, String key);

  Future<void> checkEmailExists(String email);

  Future<String> getUserToken(String token);

  Future<void> updatePassword(
    String password,
    String userId,
  );

  Future<void> checkOldPassword(
    String oldPassword,
    String password,
    String userId,
  );

  Future<String> refreshToken(String refreshToken);

  Future<UserStatus> updatePremiumStatus(String pmtId, String premiumId, String token);
}
