import 'package:bloc/bloc.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/question/question_model.dart';
import 'package:optombai/data/repositories/i_settings_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:optombai/configs/constrants.dart';

part 'question_event.dart';

part 'question_state.dart';

class QuestionBloc extends Bloc<QuestionEvent, QuestionState> {
  final ISettingsRepository _repository;
  final SharedPreferences preferences;

  QuestionBloc({required ISettingsRepository repository, required this.preferences})
      : _repository = repository,
        super(const QuestionState()) {
    on<QuestionCreateEvent>(onQuestionCreate);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  onQuestionCreate(QuestionCreateEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.createQuestion(
        event.question,
        getToken(),
      );
      emit(state.copyWith(isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }
}
