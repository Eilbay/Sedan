part of 'block_bloc.dart';

@immutable
abstract class BlockEvent extends Equatable {
  const BlockEvent();

  @override
  List<Object?> get props => const [];
}

class LoadBlocksEvent extends BlockEvent {
  final bool forceRefresh;

  const LoadBlocksEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class BlockUserEvent extends BlockEvent {
  final String userId;
  final String? reason;

  const BlockUserEvent({required this.userId, this.reason});

  @override
  List<Object?> get props => [userId, reason];
}

class UnblockUserEvent extends BlockEvent {
  final String userId;

  const UnblockUserEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Clears one-shot transient flags (justBlockedUserId / justUnblockedUserId)
/// so listeners do not re-trigger snackbars after navigation.
class ResetBlockStatusEvent extends BlockEvent {
  const ResetBlockStatusEvent();
}
