part of 'button_visible_bloc.dart';

class ButtonVisibleState extends Equatable {

  const ButtonVisibleState({
    this.status = FormStatus.pure,
    this.statusChangeMode = FormStatus.pure,
    this.isVisible = true,
    this.error = '',
  });

  final FormStatus status;
  final FormStatus statusChangeMode;
  final String error;
  final bool isVisible;

  ButtonVisibleState copyWith({
    FormStatus? status,
    FormStatus? statusChangeMode,
    String? error,
    bool? isVisible,
  }) {
    return ButtonVisibleState(
      status: status ?? this.status,
      statusChangeMode: statusChangeMode ?? this.statusChangeMode,
      error: error ?? this.error,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  List<Object> get props => [
    status,
    statusChangeMode,
    isVisible,
    error
  ];
}
