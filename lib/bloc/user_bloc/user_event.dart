part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {}

class UserOwnerEvent extends UserEvent {
  @override
  List<Object?> get props => [];
}

class FetchUsersByTypeAndCountry extends UserEvent {
  final String userType;
  final String country;
  final String? categories;
  final int? market;
  final bool isVerified;

  FetchUsersByTypeAndCountry({
    required this.userType,
    required this.country,
    this.categories,
    this.market,
    this.isVerified = false,
  });

  @override
  List<Object?> get props =>
      [userType, country, categories, market, isVerified];
}

class UserPageEvent extends UserEvent {
  final String userType;
  final String country;
  final String? categories;
  final int? market;

  UserPageEvent(
      {required this.userType,
      required this.country,
      this.categories,
      this.market});

  @override
  List<Object?> get props => [userType, country, categories, market];
}

class UserGoToPageEvent extends UserEvent {
  final int page;
  final int limit;
  final String userType;
  final String? country;
  final String? categories;
  final int? market;
  final bool isVerified;

  UserGoToPageEvent(
      {required this.page,
      required this.limit,
      required this.userType,
      this.country,
      this.categories,
      this.market,
      this.isVerified = false});

  @override
  List<Object?> get props =>
      [page, limit, userType, country, categories, market, isVerified];
}

/// Appends the next page of the customers list (infinite scroll) using the
/// server-provided `next` URL kept in state. No-op when there is no next
/// page or a load is already in flight.
class CustomersPageEvent extends UserEvent {
  @override
  List<Object?> get props => [];
}

/// Appends the next page of user search results ("Показать ещё") using the
/// server-provided `next` URL kept in state. No-op when there is no next
/// page or a load is already in flight.
class SearchUsersPageEvent extends UserEvent {
  final String search;

  SearchUsersPageEvent({required this.search});

  @override
  List<Object?> get props => [search];
}

class ClientsPageEvent extends UserEvent {
  final String userType;
  final String country;
  final String? categories;

  ClientsPageEvent({
    required this.userType,
    required this.country,
    this.categories,
  });

  @override
  List<Object?> get props => [userType, country, categories];
}

class UserOtherEvent extends UserEvent {
  final String userId;

  UserOtherEvent(this.userId);

  @override
  List<Object?> get props => [];
}

class FetchCustomers extends UserEvent {
  final String? countryId;
  final String? categoryId;

  FetchCustomers({this.countryId, this.categoryId});

  @override
  List<Object?> get props => [countryId, categoryId];
}

class CustomersGoToPage extends UserEvent {
  final int page;
  final int limit;
  final String? countryId;
  final String? categoryId;

  CustomersGoToPage({
    required this.page,
    required this.limit,
    this.countryId,
    this.categoryId,
  });

  @override
  List<Object?> get props => [page, limit, countryId, categoryId];
}

class UserDeleteEvent extends UserEvent {
  final String userId;
  final String password;

  UserDeleteEvent(this.userId, this.password);

  @override
  List<Object?> get props => [userId, password];
}

class UserOtherWithoutTokenEvent extends UserEvent {
  final String userId;

  UserOtherWithoutTokenEvent(this.userId);

  @override
  List<Object?> get props => [];
}

class UserVisit extends UserEvent {
  final String userId;

  UserVisit(this.userId);

  @override
  List<Object?> get props => [];
}

class UserAllEvent extends UserEvent {
  @override
  List<Object?> get props => [];
}

class UserUpdateEvent extends UserEvent {
  final String id;
  final Map<String, dynamic> map;

  UserUpdateEvent({required this.id, required this.map});

  @override
  List<Object?> get props => [id, map];
}

// ignore: must_be_immutable
class UserUpdateEmail extends UserEvent {
  late String email;

  UserUpdateEmail({
    required this.email,
  });

  @override
  List<Object?> get props => [
        email,
      ];
}

class UpdateEmail extends UserEvent {
  final String email;
  final String code;

  UpdateEmail({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}

class SocialOwnerEvent extends UserEvent {
  final SocialOwner socialOwner;
  final EnumRequestType typeRequest;

  SocialOwnerEvent(this.socialOwner, this.typeRequest);

  @override
  List<Object?> get props => [];
}

class ImageUserUpdateEvent extends UserEvent {
  final String id;
  final File file;

  ImageUserUpdateEvent({required this.id, required this.file});

  @override
  List<Object?> get props => [id, file];
}

class UpdateUserActive extends UserEvent {
  final int profileViewCount;
  final int profileViewsCountManafacturer;

  UpdateUserActive({
    required this.profileViewCount,
    required this.profileViewsCountManafacturer,
  });

  @override
  List<Object?> get props => [profileViewCount, profileViewsCountManafacturer];
}

class SearchUsersEvent extends UserEvent {
  final String search;
  final int page;
  final int limit;
  final String? categoryId;
  final int? countryId;
  final String? ordering;

  SearchUsersEvent({
    required this.search,
    required this.page,
    required this.limit,
    this.categoryId,
    this.countryId,
    this.ordering,
  });

  @override
  List<Object?> get props =>
      [search, page, limit, categoryId, countryId, ordering];
}
