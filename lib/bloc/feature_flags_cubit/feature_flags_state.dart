part of 'feature_flags_cubit.dart';

class FeatureFlagsState extends Equatable {
  const FeatureFlagsState({
    this.status = FormStatus.pure,
    this.flags = const {},
    this.error = '',
  });

  final FormStatus status;
  final Map<String, bool> flags;
  final String error;

  /// A key absent from the server payload is treated as hidden, so a
  /// feature can be removed the moment this cubit is wired in — no
  /// Firebase write required — and re-enabled later by adding the key.
  bool isVisible(String key) => flags[key] ?? false;

  FeatureFlagsState copyWith({
    FormStatus? status,
    Map<String, bool>? flags,
    String? error,
  }) {
    return FeatureFlagsState(
      status: status ?? this.status,
      flags: flags ?? this.flags,
      error: error ?? this.error,
    );
  }

  @override
  List<Object> get props => [status, flags, error];
}
