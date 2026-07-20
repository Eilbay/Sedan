part of 'report_cubit.dart';

class ReportState extends Equatable {
  final bool isSubmitting;
  final bool isSuccess;
  final bool alsoBlocked;
  final List<String> errors;
  final ReportModel? lastReport;

  const ReportState({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.alsoBlocked = false,
    this.errors = const [],
    this.lastReport,
  });

  ReportState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    bool? alsoBlocked,
    List<String>? errors,
    ReportModel? lastReport,
  }) {
    return ReportState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      alsoBlocked: alsoBlocked ?? this.alsoBlocked,
      errors: errors ?? this.errors,
      lastReport: lastReport ?? this.lastReport,
    );
  }

  @override
  List<Object?> get props =>
      [isSubmitting, isSuccess, alsoBlocked, errors, lastReport];
}
