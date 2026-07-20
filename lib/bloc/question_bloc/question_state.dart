part of 'question_bloc.dart';

class QuestionState extends Equatable {
  final bool isLoading;
  final bool isLoadingSend;
  final List<String> errors;
  final bool isSuccess;
  final QuestionModel? question;

  const QuestionState({
    this.isLoading = false,
    this.isLoadingSend = false,
    this.errors = const [],
    this.isSuccess = false,
    this.question,
  });

  copyWith(
      {bool isLoading = false,
      bool isLoadingSend = false,
      List<String> errors = const [],
      List<QuestionModel> question = const [],
      bool isSuccess = false}) {
    return QuestionState(
        isLoading: isLoading,
        isLoadingSend: isLoadingSend,
        errors: errors,
        isSuccess: isSuccess);
  }

  @override
  List<Object?> get props => [isLoading, errors, isSuccess, isLoadingSend,question];
}
