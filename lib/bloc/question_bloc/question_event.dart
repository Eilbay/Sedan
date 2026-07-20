part of 'question_bloc.dart';

@immutable
abstract class QuestionEvent extends Equatable {}

class QuestionCreateEvent extends QuestionEvent {
  final QuestionModel question;

  QuestionCreateEvent({required this.question});

  @override
  List<Object?> get props => [question];
}
