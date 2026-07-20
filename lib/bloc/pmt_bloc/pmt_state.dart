import 'package:optombai/data/models/pmt/pmt_model.dart';
import 'package:equatable/equatable.dart';

class PmtState extends Equatable {
  final bool isLoading;
  final bool isLoadingSend;
  final List<String> errors;
  final bool isSuccess;
  final List<PmtModel> list;
  final String? pmtStatus;
  final String? pmtRedirectUrl;
  final PmtModel? currentPmt;

  const PmtState({
    this.isLoading = false,
    this.isLoadingSend = false,
    this.errors = const [],
    this.list = const [],
    this.isSuccess = false,
    this.pmtStatus,
    this.pmtRedirectUrl,
    this.currentPmt,
  });

  PmtState copyWith({
    bool? isLoading,
    bool? isLoadingSend,
    List<String>? errors,
    bool? isSuccess,
    List<PmtModel>? list,
    String? pmtStatus,
    String? pmtRedirectUrl,
    PmtModel? currentPmt,
  }) {
    return PmtState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingSend: isLoadingSend ?? this.isLoadingSend,
      errors: errors ?? this.errors,
      isSuccess: isSuccess ?? this.isSuccess,
      list: list ?? this.list,
      pmtStatus: pmtStatus ?? this.pmtStatus,
      pmtRedirectUrl: pmtRedirectUrl ?? this.pmtRedirectUrl,
      currentPmt: currentPmt ?? this.currentPmt,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingSend,
        errors,
        isSuccess,
        list,
        pmtStatus,
        pmtRedirectUrl,
        currentPmt
      ];
}
