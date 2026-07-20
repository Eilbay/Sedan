part of 'admin_request_bloc.dart';

class AdminRequestState extends Equatable {
  final bool isLoading;
  final List<String> errors;
  final bool isSuccess;

  const AdminRequestState({
    this.isLoading = false,
    this.errors = const [],
    this.isSuccess = false,
  });

  copyWith({
    bool isLoading = false,
    List<String> errors = const [],
    bool isSuccess = false,
  }) {
    return AdminRequestState(
      isLoading: isLoading,
      errors: errors,
      isSuccess: isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errors,
        isSuccess,
      ];
}
