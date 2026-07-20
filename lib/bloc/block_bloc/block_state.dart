part of 'block_bloc.dart';

class BlockState extends Equatable {
  final bool isLoading;
  final bool isMutating;
  final bool isSuccess;
  final List<BlockModel> results;
  final Set<String> blockedIds;
  final List<String> errors;

  /// One-shot id of a user that was just blocked — used for snackbars/listeners.
  /// Cleared via [ResetBlockStatusEvent].
  final String justBlockedUserId;

  /// One-shot id of a user that was just unblocked.
  final String justUnblockedUserId;

  const BlockState({
    this.isLoading = false,
    this.isMutating = false,
    this.isSuccess = false,
    this.results = const [],
    this.blockedIds = const {},
    this.errors = const [],
    this.justBlockedUserId = '',
    this.justUnblockedUserId = '',
  });

  BlockState copyWith({
    bool? isLoading,
    bool? isMutating,
    bool? isSuccess,
    List<BlockModel>? results,
    Set<String>? blockedIds,
    List<String>? errors,
    String? justBlockedUserId,
    String? justUnblockedUserId,
  }) {
    return BlockState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      isSuccess: isSuccess ?? this.isSuccess,
      results: results ?? this.results,
      blockedIds: blockedIds ?? this.blockedIds,
      errors: errors ?? this.errors,
      justBlockedUserId: justBlockedUserId ?? this.justBlockedUserId,
      justUnblockedUserId: justUnblockedUserId ?? this.justUnblockedUserId,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isMutating,
        isSuccess,
        results,
        blockedIds,
        errors,
        justBlockedUserId,
        justUnblockedUserId,
      ];
}
