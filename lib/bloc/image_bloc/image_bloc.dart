import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/image/image_model.dart';
import 'package:optombai/data/repositories/i_image_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:optombai/configs/constrants.dart';

part 'image_event.dart';

part 'image_state.dart';

class ImageBloc extends Bloc<ImageEvent, ImageState> {
  final IImageRepository _repository;
  final SharedPreferences preferences;

  ImageBloc({required IImageRepository repository, required this.preferences})
      : _repository = repository,
        super(const ImageState()) {
    on<ImageCreateEvent>(onCreateImage);
    on<GetAllImage>(onGetAllImage);
    on<ImageDelete>(onDeleteImage);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  onDeleteImage(ImageDelete event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteOrgPhoto(event.id, getToken());

      emit(state.deleteImage(event.id));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  onGetAllImage(GetAllImage event, emit) async {
    if (state.results.isNotEmpty) return;

    final token = getToken();
    if (token.isEmpty) return;

    emit(state.copyWith(isLoading: true));
    try {
      var results = await _repository.getOrgPhotos(event.userId, token);
      emit(state.copyWith(isSuccess: true, results: results));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  onCreateImage(ImageCreateEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.createOrgPhoto(
          getToken(), event.photos, event.userId);
      emit(state.copyWith(isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }
}
