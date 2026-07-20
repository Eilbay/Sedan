import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/report/report_category.dart';
import 'package:optombai/data/models/report/report_target_type.dart';

/// Single report record returned by POST /reports/.
class ReportModel extends Equatable {
  /// Backend returns a UUID string, not a numeric id.
  final String id;
  final ReportTargetType targetType;
  final String targetId;
  final ReportCategory category;
  final String? reason;
  final String status;
  final DateTime? createdAt;

  const ReportModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.category,
    this.reason,
    this.status = 'new',
    this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: (json['id'] ?? '').toString(),
      targetType:
          ReportTargetType.fromWire((json['target_type'] ?? 'post') as String),
      targetId: (json['target_id'] ?? '').toString(),
      category: ReportCategory.fromWire((json['category'] ?? 'other') as String),
      reason: json['reason'] as String?,
      status: (json['status'] ?? 'new') as String,
      createdAt: _parseDate(json['created_at']),
    );
  }

  @override
  List<Object?> get props =>
      [id, targetType, targetId, category, reason, status, createdAt];
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
