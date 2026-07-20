import 'package:bloc/bloc.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/account/user/socials/social_type.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';
import 'package:equatable/equatable.dart';

import 'package:optombai/data/models/account/user/socials/social_owner.dart';

part 'social_types_event.dart';

part 'social_types_state.dart';

class SocialTypesBloc extends Bloc<SocialTypesEvent, SocialTypesState> {
  final IUserRepository _repository;

  SocialTypesBloc({required IUserRepository repository})
      : _repository = repository,
        super(const SocialTypesState()) {
    on<SocialsGetEvent>(_getSocialsType);
    on<SocialsGet>(_getSocials);
  }

  _getSocialsType(SocialsGetEvent event, emit) async {
    try {
      var list = await _repository.getSocialTypes();
      emit(state.copyWith(socialsTypes: list));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  _getSocials(SocialsGet event, emit) async {
    try {
      var list = await _repository.getSocial(event.id);
      emit(state.copyWith(socialOwner: list));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }
}
