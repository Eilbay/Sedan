import 'package:equatable/equatable.dart';

class VisitModel extends Equatable {
  final int count;
  final String? next;
  final String? preview;
  final List<UserActive> results;

  const VisitModel(
      {this.count = 0, this.next, this.preview, this.results = const []});

  VisitModel copyWith(
      {int? count, String? next, String? preview, List<UserActive>? results}) {
    return VisitModel(
        count: count ?? this.count,
        next: next ?? this.next,
        preview: preview ?? this.preview,
        results: results ?? this.results);
  }

  VisitModel.fromJson(Map<String, dynamic> json)
      : count = json["count"],
        next = json["next"],
        preview = json["preview"],
        results = json["results"]
            .map((item) => UserActive.fromJson(item))
            .cast<UserActive>()
            .toList();

  @override
  List<Object?> get props => [count, next, preview, results];
}

class UserActive extends Equatable {
  final int? id;
  final int? premium;
  final int? profileViewCount;
  final int? profileViewsCountManafacturer;
  final String? user;
  final String? startTime;
  final String? expiredDate;

  const UserActive({
    this.id,
    this.premium,
    this.user,
    this.profileViewCount = 0,
    this.profileViewsCountManafacturer = 0,
    this.startTime,
    this.expiredDate,
  });

  factory UserActive.fromJson(Map<String, dynamic> json) {
    return UserActive(
      id: json['id'] ?? 0,
      premium: json['premium'],
      user: json['user'] ?? '',
      profileViewCount: json['profile_views_count'] ?? 0,
      profileViewsCountManafacturer:
          json['profile_views_count_manafacturer'] ?? 0,
      startTime: json['start_time'] ?? "",
      expiredDate: json['expired_date'] ?? "",
    );
  }

  UserActive copyWith({
    int? id,
    int? premium,
    int? profileViewCount,
    int? profileViewsCountManafacturer,
    String? user,
    String? startTime,
    String? expiredDate,
  }) {
    return UserActive(
      id: id ?? this.id,
      premium: premium ?? this.premium,
      profileViewCount: profileViewCount ?? this.profileViewCount,
      profileViewsCountManafacturer:
          profileViewsCountManafacturer ?? this.profileViewsCountManafacturer,
      user: user ?? this.user,
      startTime: startTime ?? this.startTime,
      expiredDate: expiredDate ?? this.expiredDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        premium,
        profileViewCount,
        profileViewsCountManafacturer,
        user,
        startTime,
        expiredDate,
      ];
}
