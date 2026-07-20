import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/data/models/account/user/users_activiti.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/services/chat_auth_guard.dart';

part 'user_event.dart';

part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final IUserRepository _repository;
  final SharedPreferences preferences;

  UserBloc({required IUserRepository repository, required this.preferences})
      : _repository = repository,
        super(UserState(
            user: User(), otherUser: User(), otherUserWithoutToken: User())) {
    on<UserOwnerEvent>(_onGetUser);
    on<UserUpdateEvent>(_onInfoUserUpdate);
    on<ImageUserUpdateEvent>(_onImageUserUpdate);
    on<UserUpdateEmail>(_onUpdateEmailSendCode);
    on<UpdateEmail>(_updateEmail);
    on<SocialOwnerEvent>(_socialsAddOrUpdate);
    on<UserOtherEvent>(_onGetUserOther);
    on<UserOtherWithoutTokenEvent>(_onGetUserOtherWithoutToken);
    on<UserVisit>(_onGetVisitsProfileCount);
    on<UserDeleteEvent>(_onDeleteUser);
    on<UpdateUserActive>(_onUpdateUserActive);
    on<FetchUsersByTypeAndCountry>(_onFetchUsersByTypeAndCountry);
    on<FetchCustomers>(_onFetchCustomers);
    on<CustomersGoToPage>(_onCustomersGoToPage);
    on<CustomersPageEvent>(_onCustomersPageEvent);

    on<UserPageEvent>(_onUserPageEvent);
    on<UserGoToPageEvent>(_onUserGoToPageEvent);
    on<SearchUsersEvent>(_onSearchUsers);
    on<SearchUsersPageEvent>(_onSearchUsersPage);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  Future<void> _onFetchCustomers(
    FetchCustomers event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      const limit = 20;
      final res = await _repository.getCustomers(
        token: getToken(),
        countryId: event.countryId,
        categoryId: event.categoryId,
        page: 1,
        limit: limit,
      );

      final users = (res['users'] as List<User>?) ?? <User>[];
      final count = (res['count'] as int?) ?? 0;

      emit(state.copyWith(
        notifications: users,
        count: count,
        next: res['next'] as String?,
        isSuccess: true,
        isLoading: false,
        currentPage: 1,
        totalPages: (count / limit).ceil(),
        isLoadingPaginate: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onCustomersGoToPage(
    CustomersGoToPage event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isLoadingPaginate: true));

    try {
      final res = await _repository.getCustomers(
        token: getToken(),
        countryId: event.countryId,
        categoryId: event.categoryId,
        page: event.page,
        limit: event.limit,
      );

      final users = (res['users'] as List<User>?) ?? <User>[];
      final count = (res['count'] as int?) ?? 0;

      emit(state.copyWith(
        notifications: users,
        count: count,
        next: res['next'] as String?,
        isSuccess: true,
        isLoadingPaginate: false,
        currentPage: event.page,
        totalPages: (count / event.limit).ceil(),
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingPaginate: false));
    }
  }

  /// Infinite-scroll append for the customers list — mirrors
  /// [_onUserPageEvent]: the server `next` URL carries all active filters.
  Future<void> _onCustomersPageEvent(
    CustomersPageEvent event,
    Emitter<UserState> emit,
  ) async {
    if (state.next == null || state.isLoadingPaginate) return;

    emit(state.copyWith(isLoadingPaginate: true));

    try {
      final res = await _repository.getCustomers(
        token: getToken(),
        nextUrl: state.next,
      );

      final users = (res['users'] as List<User>?) ?? <User>[];
      emit(state.addPaginatedUsers(users, res['next'] as String?));
    } on AppException catch (e) {
      emit(state.copyWith(isLoadingPaginate: false, errors: e.messages));
    } catch (_) {
      emit(state.copyWith(isLoadingPaginate: false));
    }
  }

  Future<void> _onUserGoToPageEvent(
    UserGoToPageEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final response = await _repository.getUsersByTypeAndCountry(
          userType: event.userType,
          country: event.country,
          categories: event.categories,
          page: event.page,
          limit: event.limit,
          market: event.market,
          isVerified: event.isVerified);

      final List<User> users = response['users'] ?? const <User>[];
      final int count = response['count'] ?? state.count ?? 0;
      final int limit = event.limit;
      final int totalPages = (count / limit).ceil();

      emit(state.copyWith(
        notifications: users,
        count: count,
        currentPage: event.page,
        totalPages: totalPages,
        isLoading: false,
        isSuccess: true,
        next: response['next'],
        isLoadingPaginate: false,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isLoading: false, errors: e.messages));
    }
  }

  _onGetUserOther(UserOtherEvent event, emit) async {
    // Reset both the cached profile and the not-found flag so the UI
    // doesn't briefly render the previous user (or its 404 stub) while
    // the new fetch is in flight.
    emit(state.copyWith(
      isLoading: true,
      otherUser: User(),
      otherUserNotFound: false,
      otherUserBlockedByThem: false,
    ));
    try {
      var user = await _repository.getUser(getToken(), event.userId);
      emit(state.copyWith(otherUser: user, isSuccess: true));
    } on BlockedException {
      // 403 + code=BLOCKED — the target user has blocked the viewer, so the
      // backend forbids reading the profile. Distinct from a 404 (deleted):
      // the UI shows "Вас заблокировал этот пользователь".
      emit(state.copyWith(otherUserBlockedByThem: true));
    } on NotFoundException {
      // 404 — the profile is genuinely gone (deleted / never existed). Note:
      // "I blocked them" returns 200 with is_blocked_by_me=true, so it does
      // NOT reach here.
      emit(state.copyWith(otherUserNotFound: true));
    } on AppException catch (e) {
      debugPrint('$e');
      emit(state.copyWith(errors: e.messages));
    }
  }

  Future<void> _onUserPageEvent(
      UserPageEvent event, Emitter<UserState> emit) async {
    if (state.next == null || state.isLoadingPaginate) return;

    emit(state.copyWith(isLoadingPaginate: true));

    try {
      final response = await _repository.getUsersByTypeAndCountry(
          nextUrl: state.next,
          userType: event.userType,
          country: event.country,
          categories: event.categories,
          market: event.market);
      final List<User> users = response['users'];
      final String? next = response['next'];

      emit(state.addPaginatedUsers(users, next));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoadingPaginate: false,
        errors: e.messages,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingPaginate: false));
    }
  }

  _onFetchUsersByTypeAndCountry(FetchUsersByTypeAndCountry event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      const limit = 20;
      final response = await _repository.getUsersByTypeAndCountry(
          userType: event.userType,
          country: event.country,
          categories: event.categories,
          page: 1,
          limit: limit,
          market: event.market,
          isVerified: event.isVerified);

      final count = response['count'] as int? ?? 0;
      final totalPages = (count / limit).ceil();

      emit(state.copyWith(
        notifications: response['users'],
        next: response['next'],
        count: count,
        isSuccess: true,
        isLoadingPaginate: false,
        currentPage: 1,
        totalPages: totalPages,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  _onUpdateUserActive(UpdateUserActive event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      var updatedUser = await _repository.infoUserUpdate(
          getToken(),
          {
            "profile_views_count": event.profileViewCount,
            "profile_views_count_manafacturer":
                event.profileViewsCountManafacturer,
          },
          state.user.id);

      emit(state.copyWith(user: updatedUser, isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  _onGetUserOtherWithoutToken(UserOtherWithoutTokenEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      var user = await _repository.getUserWithoutToken(event.userId);
      emit(state.copyWith(otherUserWithoutToken: user, isSuccess: true));
    } on AppException catch (e) {
      debugPrint('$e');
      emit(state.copyWith(errors: e.messages));
    }
  }

  _onGetVisitsProfileCount(UserVisit event, emit) async {
    final token = getToken();
    if (token.isEmpty) return;

    emit(state.copyWith(isLoading: true));
    try {
      var user = await _repository.getVisitProfileCount(token, event.userId);
      emit(state.copyWith(
        isSuccess: true,
        userActive: user,
      ));
    } on AppException catch (e) {
      debugPrint(e.message);
      emit(state.copyWith(errors: e.messages));
    }
  }

  _socialsAddOrUpdate(SocialOwnerEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      var user = await _repository.socialAddOrUpdate(
          getToken(), event.socialOwner, event.typeRequest);
      emit(state.copyWith(user: user, isSuccessSocials: true));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  _onGetUser(UserOwnerEvent event, emit) async {
    debugPrint('[AUTH] UserBloc._onGetUser requested');
    String token = '';
    try {
      token = await getIt<ChatAuthGuard>().requireToken(
        timeout: const Duration(seconds: 2),
      );
    } on AuthException {
      token = '';
    }

    if (token.isEmpty) {
      debugPrint('[AUTH] UserBloc._onGetUser no token -> exit');
      emit(state.copyWith(isExit: true));
      return;
    }

    debugPrint('[AUTH] UserBloc._onGetUser token ready len=${token.length}');
    emit(state.copyWith(isLoading: true));
    try {
      var user = await _repository.getUserOwner(token);
      debugPrint('[AUTH] UserBloc._onGetUser success');
      emit(state.copyWith(user: user, isSuccess: true));
    } on AppException catch (e) {
      debugPrint('[AUTH] UserBloc._onGetUser error=${e.messages}');
      emit(state.copyWith(errors: e.messages));
    }
  }

  _onInfoUserUpdate(UserUpdateEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      var user =
          await _repository.infoUserUpdate(getToken(), event.map, event.id);

      emit(state.copyWith(user: user, isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  _onImageUserUpdate(ImageUserUpdateEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      var user = await _repository.userImage(getToken(), event.file, event.id);
      emit(state.copyWith(user: user, isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  _onUpdateEmailSendCode(UserUpdateEmail event, emit) async {
    emit(state.copyWith(isLoadingEmail: true));
    try {
      await _repository.newEmailCode(event.email, getToken());
      emit(state.copyWith());
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  _updateEmail(UpdateEmail event, emit) async {
    emit(state.copyWith(isLoadingEmail: true));
    try {
      await _repository.updateEmail(event.email, event.code, getToken());
      emit(state.copyWith());
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  _onDeleteUser(UserDeleteEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteUser(getToken(), event.userId, event.password);

      await preferences.clear();

      emit(state.copyWith(isLoading: false, isSuccess: true, isExit: true));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final res = await _repository.searchUsers(
        search: event.search,
        page: event.page,
        limit: event.limit,
        categoryId: event.categoryId,
        countryId: event.countryId,
        ordering: event.ordering,
      );

      final users = (res['users'] as List<User>?) ?? <User>[];
      final count = (res['count'] as int?) ?? 0;
      final totalPages = (count / event.limit).ceil();

      emit(state.copyWith(
        notifications: users,
        count: count,
        next: res['next'] as String?,
        isSuccess: true,
        isLoading: false,
        currentPage: event.page,
        totalPages: totalPages == 0 ? 1 : totalPages,
        isLoadingPaginate: false,
        errors: const [],
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// "Показать ещё" append for user search results — mirrors
  /// [_onUserPageEvent]: the server `next` URL carries the search query and
  /// all active filters.
  Future<void> _onSearchUsersPage(
    SearchUsersPageEvent event,
    Emitter<UserState> emit,
  ) async {
    if (state.next == null || state.isLoadingPaginate) return;

    emit(state.copyWith(isLoadingPaginate: true));

    try {
      final res = await _repository.searchUsers(
        search: event.search,
        nextUrl: state.next,
      );

      final users = (res['users'] as List<User>?) ?? <User>[];
      emit(state.addPaginatedUsers(users, res['next'] as String?));
    } on AppException catch (e) {
      emit(state.copyWith(isLoadingPaginate: false, errors: e.messages));
    } catch (_) {
      emit(state.copyWith(isLoadingPaginate: false));
    }
  }
}
