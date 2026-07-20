class StreamBanModel {
  final String streamId;
  final String userId;
  final String? until;
  final String? reason;
  final bool active;

  const StreamBanModel({
    required this.streamId,
    required this.userId,
    this.until,
    this.reason,
    required this.active,
  });

  factory StreamBanModel.fromJson(Map<String, dynamic> json) {
    return StreamBanModel(
      streamId: json['stream_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      until: json['until']?.toString(),
      reason: json['reason']?.toString(),
      active: json['active'] is bool ? json['active'] as bool : false,
    );
  }
}
