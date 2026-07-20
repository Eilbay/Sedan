import 'package:equatable/equatable.dart';

abstract class SupportEvent extends Equatable {
  const SupportEvent();
}

class CheckActiveSupportSessionEvent extends SupportEvent {
  @override
  List<Object?> get props => [];
}

class StartSupportSessionEvent extends SupportEvent {
  final String text;

  const StartSupportSessionEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class CloseSupportSessionEvent extends SupportEvent {
  final String sessionId;
  final String comment;

  const CloseSupportSessionEvent({
    required this.sessionId,
    required this.comment,
  });

  @override
  List<Object?> get props => [sessionId, comment];
}

class ClearSupportEvent extends SupportEvent {
  @override
  List<Object?> get props => [];
}
