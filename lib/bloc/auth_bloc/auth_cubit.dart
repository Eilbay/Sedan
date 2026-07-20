import 'package:collection/collection.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/auth_bloc/auth_state.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/account/token.dart';
import 'package:optombai/data/models/account/user/user_status.dart';
import 'package:optombai/data/repositories/i_auth_repository.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCubit extends Cubit<AuthState> {
  final IAuthRepository _repository;
  final SharedPreferences preferences;
  String? _pendingUsername;
  String? _pendingPassword;

  AuthCubit({required IAuthRepository repository, required this.preferences})
      : _repository = repository,
        super(AuthInitial());

  _setToken(Token token) async {
    debugPrint(
      '[AUTH] AuthCubit._setToken accessLen=${token.access.length} '
      'refreshLen=${token.refresh.length}',
    );
    await preferences.setString(TOKEN_KEY, token.access);
    await preferences.setString(REFRESH_TOKEN_KEY, token.refresh);
  }

  Token _getToken() {
    String access = preferences.getString(TOKEN_KEY) ?? "";
    String refresh = preferences.getString(REFRESH_TOKEN_KEY) ?? "";
    return Token(access: access, refresh: refresh);
  }

  Future<String> confirmResetByPhone({
    required String phoneNumber,
    required String code,
  }) async {
    emit(AuthLoading());
    try {
      final userId = await _repository.confirmResetCodeByPhone(
        phoneNumber: phoneNumber,
        code: code,
      );
      emit(AuthStateCodeSuccess());
      return userId;
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
      return "";
    } catch (e) {
      emit(AuthStateError([e.toString().replaceFirst('Exception: ', '')]));
      return "";
    }
  }

  Future<void> fetchUserCountForType(
    String userType, {
    String? categories,
  }) async {
    emit(AuthLoading());
    try {
      final int userCount = await _repository.getUserCountByType(
        userType,
        categories: categories,
      );
      emit(UserCountSuccess(userCount));
    } on AppException catch (e) {
      debugPrint('$e');
      emit(AuthStateError(e.messages));
    }
  }

  Future<void> fetchClientCountForType(
    String userType, {
    String? categories,
  }) async {
    emit(AuthLoading());
    try {
      final int userCount = await _repository.getClientCountByType(
        userType,
        categories: categories,
      );
      emit(UserCountSuccess(userCount));
    } on AppException catch (e) {
      debugPrint('$e');
      emit(AuthStateError(e.messages));
    }
  }

  Future<void> googleAuth(String token) async {
    debugPrint('[AUTH] googleAuth() tokenLen=${token.length}');
    emit(AuthLoading());
    try {
      final loginUser = await _repository.googleAuth(token);
      await _setToken(loginUser);
      emit(LoginStateSuccess());
    } on AppException catch (e) {
      debugPrint('$e');
      emit(AuthStateError(e.messages));
    } catch (e, st) {
      // Same defence as in login(): keep the spinner from getting stuck
      // when the unexpected exception path is hit.
      debugPrint('googleAuth() unexpected error: $e\n$st');
      emit(AuthStateError([e.toString().replaceFirst('Exception: ', '')]));
    }
  }

  Future<void> authenticateUser({
    String? email,
    required String password,
    required String username,
    required String phoneNumber,
    int? regionId,
  }) async {
    debugPrint(
      '[AUTH] authenticateUser() username=$username email=$email '
      'phone=$phoneNumber regionId=$regionId',
    );
    await registerForVerification(
      email: email,
      password: password,
      username: username,
      phoneNumber: phoneNumber,
      regionId: regionId,
    );

    emit(AuthLoading());
    try {
      final data = await _repository.registerUser(
        email: email,
        password: password,
        username: username,
        phoneNumber: phoneNumber,
        regionId: regionId,
        isEmailConfirmation: false,
      );

      final access = (data['access_token'] ?? '').toString();
      final refresh = (data['refresh_token'] ?? '').toString();
      if (access.isNotEmpty && refresh.isNotEmpty) {
        await _setToken(Token(access: access, refresh: refresh));
        emit(LoginStateSuccess());
        return;
      }

      final tokens = await _repository.login(username, password);
      await _setToken(tokens);
      emit(LoginStateSuccess());
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
    } catch (_) {
      emit(const AuthStateError(['Неизвестная ошибка при регистрации']));
    }
  }

  Future<void> registerForVerification({
    String? email,
    required String password,
    required String username,
    required String phoneNumber,
    int? regionId,
    String? referralCode,
  }) async {
    debugPrint(
      '[AUTH] registerForVerification() username=$username email=$email '
      'phone=$phoneNumber regionId=$regionId referralCode=$referralCode',
    );
    emit(AuthLoading());
    try {
      await _repository.registerUser(
        email: email,
        password: password,
        username: username,
        phoneNumber: phoneNumber,
        regionId: regionId,
        isEmailConfirmation: false,
        referralCode: referralCode,
      );

      _pendingUsername = username;
      _pendingPassword = password;

      emit(RegistrationPendingCode(
        username: username,
        password: password,
        phone: phoneNumber,
        email: email,
      ));
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
    } catch (_) {
      emit(const AuthStateError(['Неизвестная ошибка при регистрации']));
    }
  }

  Future<void> sendResetPasswordRequest(
      String value, String endpoint, String key) async {
    emit(AuthLoading());
    try {
      await _repository.sendResetPasswordRequest(value, endpoint, key);
      emit(AuthStateSuccess());
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
    }
  }

  Future<void> clear(String id) async {
    debugPrint(
      '[AUTH] clear() for user=$id tokenBefore=${_getToken().access.isNotEmpty}',
    );
    await _setToken(const Token(access: "", refresh: ""));
    emit(AuthInitial());
  }

  Future<void> login(
    String username,
    String password,
  ) async {
    debugPrint(
      '[AUTH] login() username=$username passwordLen=${password.length}',
    );
    emit(AuthLoading());
    try {
      final loginUser = await _repository.login(username, password);
      await _setToken(loginUser);
      debugPrint('[AUTH] login() success');
      emit(LoginStateSuccess());
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
    } catch (e, st) {
      // Defence: anything not surfaced as AppException (e.g. Token.fromMap
      // TypeError when the backend returns a non-standard payload) used to
      // leave the cubit stuck in AuthLoading — the "Войти" button stayed
      // spinning forever. Always release the spinner with a generic error.
      debugPrint('login() unexpected error: $e\n$st');
      emit(AuthStateError([e.toString().replaceFirst('Exception: ', '')]));
    }
  }

  Future<void> activeAccount(
    String token,
    String username,
    String password,
  ) async {
    debugPrint(
      '[AUTH] activeAccount() username=$username tokenLen=${token.length}',
    );
    emit(AuthLoading());
    try {
      final active = await _repository.activateAccount(token);

      if (active.isNotEmpty && active == "activated") {
        try {
          final loginUser = await _repository.login(username, password);
          _setToken(loginUser);
          emit(AuthStateCodeSuccess());
        } catch (_) {
          emit(const AuthStateError([
            "Произошла ошибка во время верификации, пожалуйста обратитесь к администратору"
          ]));
        }
      } else {
        emit(const AuthStateInvalidCode());
      }
    } on AppException catch (e) {
      final msg = e.message.toLowerCase();
      final isInvalidCode = [400, 401, 422].contains(e.statusCode) &&
          (msg.contains('invalid') ||
              msg.contains('wrong') ||
              msg.contains('otp') ||
              msg.contains('неверн') ||
              msg.contains('неправил'));
      if (isInvalidCode) {
        emit(const AuthStateInvalidCode());
      } else {
        emit(AuthStateError(e.messages));
      }
    } catch (_) {
      emit(const AuthStateInvalidCode());
    }
  }

  Future<void> activateAccount(String token) async {
    emit(AuthLoading());
    try {
      final active = await _repository.activateAccount(token);
      if (active.isNotEmpty && active == "activated") {
        emit(AuthStateCodeSuccess());
      } else {
        emit(const AuthStateInvalidCode());
      }
    } catch (e) {
      emit(const AuthStateInvalidCode());
    }
  }

  Future<void> checkEmailToExistUser(
    String email,
  ) async {
    emit(AuthLoading());
    try {
      await _repository.checkEmailExists(email);
      emit(AuthStateSuccess());
    } on AppException catch (e) {
      debugPrint('$e');
      emit(AuthStateError(e.messages));
    }
  }

  Future<String> getUserByToken(
    String token,
  ) async {
    emit(AuthLoading());
    try {
      final userToken = await _repository.getUserToken(token);
      emit(AuthStateCodeSuccess());
      return userToken;
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
    }
    return "";
  }

  Future<void> updatePassword(String password, String userId) async {
    emit(AuthLoading());
    try {
      await _repository.updatePassword(password, userId);
      emit(AuthStateSuccess());
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
    }
  }

  Future<void> checkOldPassword(
      String oldPassword, String password, String userId) async {
    emit(AuthLoading());
    try {
      await _repository.checkOldPassword(oldPassword, password, userId);
      emit(AuthStateSuccess());
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
    }
  }

  Future<void> refreshToken() async {
    emit(AuthLoading());
    final localToken = _getToken();

    if (localToken.refresh.isEmpty) {
      emit(const AuthStateError([], isExit: true));
      return;
    }

    try {
      final access = await _repository.refreshToken(localToken.refresh);
      _setToken(Token(access: access, refresh: localToken.refresh));
      emit(AuthStateSuccess());
    } on AppException catch (e) {
      emit(AuthStateError(e.messages,
          isExit: e is AuthException && e.isExitRequired));
    } catch (e, st) {
      // Any non-AppException (e.g. a malformed refresh response) must still
      // emit a terminal state — otherwise the splash awaits this forever.
      talker.handle(e, st, '[AUTH] refreshToken unexpected error');
      emit(const AuthStateError([], isExit: true));
    }
  }

  Future<void> updatePremiumStatus(
      String pmtId, String premiumId, BuildContext context) async {
    emit(AuthLoading());
    try {
      UserStatus userStatus =
          await _repository.updatePremiumStatus(pmtId, premiumId, getToken());

      emit(AuthStateSuccess());

      if (context.mounted) {
        showSuccessDialog(context, premiumId, userStatus);
      }
    } on AppException catch (e) {
      emit(AuthStateError(e.messages));
    }
  }

  void showSuccessDialog(
      BuildContext context, String premiumId, UserStatus userStatus) {
    var plans = context.read<SubscriptionBloc>().state.plans;

    final premiumInt = int.tryParse(premiumId);
    final selectedPlan = plans.firstWhereOrNull(
      (plan) => plan.id == premiumInt,
    );
    var planName = selectedPlan!.title;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width * 0.82,
                height: 220.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDDB5FF), Color(0xFFB3D6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Container(
                width: MediaQuery.sizeOf(context).width * 0.9,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC1E3), Color(0xFFB3D6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: TextTranslated(
                        "Поздравляем!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stateSwitch ? Colors.black : Colors.purple,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    TextTranslated(
                      "Вы успешно подключили тариф: ",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: stateSwitch ? Colors.black : null),
                    ),
                    Transform.translate(
                      offset: const Offset(3, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextTranslated(
                          '"$planName"',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          width: 150.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 62, 115, 251),
                                Color.fromARGB(255, 99, 160, 228)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: const Center(
                            child: TextTranslated(
                              "ОК",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  Future<void> verifyCodeAndLogin(String code) async {
    emit(AuthLoading());
    try {
      final active = await _repository.activateAccount(code);

      if (active.isNotEmpty && active == "activated") {
        final u = _pendingUsername ?? "";
        final p = _pendingPassword ?? "";

        if (u.isEmpty || p.isEmpty) {
          emit(const AuthStateError(
              ["Внутренняя ошибка: отсутствуют данные для входа"]));
          return;
        }

        final loginUser = await _repository.login(u, p);
        await _setToken(loginUser);
        emit(LoginStateSuccess());
      } else {
        emit(const AuthStateInvalidCode());
      }
    } on AppException catch (e) {
      final msg = e.message.toLowerCase();
      final isInvalidCode = [400, 401, 422].contains(e.statusCode) &&
          (msg.contains('invalid') ||
              msg.contains('wrong') ||
              msg.contains('otp') ||
              msg.contains('неверн') ||
              msg.contains('неправил'));
      if (isInvalidCode) {
        emit(const AuthStateInvalidCode());
      } else {
        emit(AuthStateError(e.messages));
      }
    } catch (e, s) {
      debugPrint("verifyCodeAndLogin error: $e\n$s");

      emit(const AuthStateInvalidCode());
    }
  }
}

class UserCountSuccess extends AuthState {
  final int userCount;

  const UserCountSuccess(this.userCount);

  @override
  List<Object?> get props => [userCount];
}
