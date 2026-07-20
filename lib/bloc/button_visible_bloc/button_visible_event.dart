part of 'button_visible_bloc.dart';

abstract class ButtonVisibleEvent extends Equatable {
  const ButtonVisibleEvent();

  @override
  List<Object> get props => [];
}

class LoadButtonVisible extends ButtonVisibleEvent {}

class ButtonVisibleChanged extends ButtonVisibleEvent {
  final bool isVisible;

  const ButtonVisibleChanged({
    required this.isVisible,
  });

  @override
  List<Object> get props => [isVisible];
}

class UpdateButtonVisible extends ButtonVisibleEvent {
  final bool isVisible;

  const UpdateButtonVisible(this.isVisible);

  @override
  List<Object> get props => [isVisible];
}

/// Internal event to recalculate combined visibility through the Emitter.
class _RecombineVisibility extends ButtonVisibleEvent {
  const _RecombineVisibility();
}