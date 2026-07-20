import 'package:optombai/features/promotion/data/models/promotion_package_model.dart';

class PromotionCampaignModel {
  final int id;
  final String postId;
  final String status;
  final DateTime startedAt;
  final DateTime endedAt;
  final ReachRange? reach;

  const PromotionCampaignModel({
    required this.id,
    required this.postId,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    this.reach,
  });

  bool get isActive => status == 'active' && DateTime.now().isBefore(endedAt);

  int get daysRemaining {
    if (!isActive) return 0;
    // Round partial days UP: with ~19h left the campaign is "1 день", not 0.
    // `.inDays` truncation made still-active campaigns read as "Завершена".
    final minutesLeft = endedAt.difference(DateTime.now()).inMinutes;
    if (minutesLeft <= 0) return 0;
    return (minutesLeft / (60 * 24)).ceil();
  }

  factory PromotionCampaignModel.fromJson(Map<String, dynamic> json) {
    // GET /target/campaigns/me/ returns `post`, `start_at`, `end_at`. The old
    // names (`post_id`, `started_at`, `ended_at`) never existed in the response,
    // so the cast threw a TypeError that surfaced as "Не удалось загрузить
    // данные". Keep them as fallbacks to stay robust to schema tweaks.
    final postId = (json['post'] ?? json['post_id']) as String;
    final startRaw = (json['start_at'] ?? json['started_at']) as String;
    final endRaw = (json['end_at'] ?? json['ended_at']) as String;

    // Reach is not a top-level field — it lives inside `package_snapshot`
    // (`reach_min`/`reach_max`), with the live `package` object as a fallback.
    // Without this the campaigns screen always showed "Охват: N/A".
    ReachRange? reach;
    final reachJson = json['reach'];
    if (reachJson is Map<String, dynamic>) {
      reach = ReachRange.fromJson(reachJson);
    } else {
      final source = (json['package_snapshot'] ?? json['package'])
          as Map<String, dynamic>?;
      final min = (source?['reach_min'] as num?)?.toInt();
      final max = (source?['reach_max'] as num?)?.toInt();
      if (min != null && max != null) {
        reach = ReachRange(from: min, to: max);
      }
    }

    return PromotionCampaignModel(
      id: (json['id'] as num).toInt(),
      postId: postId,
      status: json['status'] as String? ?? 'active',
      startedAt: DateTime.parse(startRaw),
      endedAt: DateTime.parse(endRaw),
      reach: reach,
    );
  }

  Map<String, dynamic> toJson() => {
        'post_id': postId,
        'status': status,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        if (reach != null) 'reach': reach!.toJson(),
      };
}

class CreateCampaignResponse {
  final String status;
  final DateTime endedAt;
  final double totalPrice;
  final double balance;
  final ReachRange? reach;

  const CreateCampaignResponse({
    required this.status,
    required this.endedAt,
    required this.totalPrice,
    required this.balance,
    this.reach,
  });

  factory CreateCampaignResponse.fromJson(Map<String, dynamic> json) {
    ReachRange? reach;
    if (json['reach'] != null) {
      reach = ReachRange.fromJson(json['reach'] as Map<String, dynamic>);
    }

    final rawTotalPrice =
        (json['total_price'] ?? json['price_paid'])?.toString() ?? '0';
    final rawBalance = json['balance']?.toString() ?? '0';
    final endRaw = (json['end_at'] ?? json['ended_at']) as String?;

    return CreateCampaignResponse(
      status: json['status'] as String? ?? 'active',
      endedAt: endRaw != null ? DateTime.parse(endRaw) : DateTime.now(),
      totalPrice: double.tryParse(rawTotalPrice) ?? 0.0,
      balance: double.tryParse(rawBalance) ?? 0.0,
      reach: reach,
    );
  }
}
