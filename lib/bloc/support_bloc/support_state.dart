import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/support/support_session_model.dart';
import 'package:optombai/data/models/chat/chat_model.dart';

class SupportState extends Equatable {
  final bool isLoading;
  final bool isSuccess;
  final List<String> errors;
  final SupportSession? activeSession;

  const SupportState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errors = const [],
    this.activeSession,
  });

  bool get hasActiveSession => activeSession != null;

  Chat? get supportChat => activeSession?.chat;
  SupportState copyWith({
    bool? isLoading,
    bool? isSuccess,
    List<String>? errors,
    SupportSession? activeSession,
    bool clearActiveSession = false,
  }) {
    return SupportState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errors: errors ?? this.errors,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSuccess,
        errors,
        activeSession,
      ];

  @override
  bool get stringify => true;
}
