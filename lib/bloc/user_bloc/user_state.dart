part of 'user_bloc.dart';

class UserState extends Equatable {
  final bool isLoading;
  final bool isLoadingEmail;
  final bool isExit;
  final List<String> errors;
  final bool isSuccess;
  final bool isSuccessSocials;
  final List<User> notifications;
  final User user;
  final List<UserActive> userActive;

  final String? next;

  final User otherUser;
  final User otherUserWithoutToken;

  /// True when `GET /accounts/users/{id}/` returned 404 — the profile is
  /// genuinely missing (deleted / never existed). UI uses this to render
  /// a "user not found" stub instead of an empty profile.
  final bool otherUserNotFound;

  /// True when `GET /accounts/users/{id}/` returned 403 with code=BLOCKED —
  /// the target user has blocked the viewer, so the backend forbids reading
  /// the profile. Distinct from [otherUserNotFound] (deleted) so the UI can
  /// show "Вас заблокировал этот пользователь" instead of "Пользователь не
  /// найден".
  final bool otherUserBlockedByThem;

  final int? count;

  final bool isLoadingPaginate;

  final int currentPage;
  final int totalPages;

  const UserState({
    this.isLoading = false,
    this.isLoadingEmail = false,
    this.errors = const [],
    this.isSuccess = false,
    this.isExit = false,
    this.isSuccessSocials = false,
    this.currentPage = 1,
    this.totalPages = 1,
    required this.user,
    this.notifications = const [],
    required this.otherUser,
    required this.otherUserWithoutToken,
    this.otherUserNotFound = false,
    this.otherUserBlockedByThem = false,
    this.userActive = const [],
    this.count,
    this.isLoadingPaginate = false,
    this.next,
  });

  UserState addPaginatedUsers(List<User> newUsers, String? nextPage) {
    final updatedList = List<User>.from(notifications)..addAll(newUsers);

    return copyWith(
      notifications: updatedList,
      next: nextPage,
      isLoadingPaginate: false,
      isSuccess: true,
    );
  }

  copyWith({
    User? user,
    bool isLoading = false,
    bool isExit = false,
    List<String> errors = const [],
    bool isSuccess = false,
    bool isSuccessSocials = false,
    bool isLoadingEmail = false,
    List<User>? notifications,
    List<UserActive>? userActive,
    User? otherUser,
    User? otherUserWithoutToken,
    bool? otherUserNotFound,
    bool? otherUserBlockedByThem,
    int? count,
    String? next,
    bool? isLoadingPaginate,
    int? currentPage,
    int? totalPages,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading,
      errors: errors,
      isSuccess: isSuccess,
      isSuccessSocials: isSuccessSocials,
      isLoadingEmail: isLoadingEmail,
      isExit: isExit,
      notifications: notifications ?? this.notifications,
      userActive: userActive ?? this.userActive,
      otherUser: otherUser ?? this.otherUser,
      otherUserWithoutToken:
          otherUserWithoutToken ?? this.otherUserWithoutToken,
      otherUserNotFound: otherUserNotFound ?? this.otherUserNotFound,
      otherUserBlockedByThem:
          otherUserBlockedByThem ?? this.otherUserBlockedByThem,
      count: count ?? this.count,
      next: next ?? this.next,
      isLoadingPaginate: isLoadingPaginate ?? this.isLoadingPaginate,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingEmail,
        isExit,
        errors,
        isSuccess,
        isSuccessSocials,
        notifications,
        user,
        userActive,
        next,
        otherUser,
        otherUserWithoutToken,
        otherUserNotFound,
        otherUserBlockedByThem,
        count,
        isLoadingPaginate,
        currentPage,
        totalPages,
      ];
}
