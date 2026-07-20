import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/image/image_model.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:optombai/configs/constrants.dart';
import 'package:optombai/data/repositories/i_image_repository.dart';

part 'document_event.dart';

part 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final IImageRepository _repository;
  final SharedPreferences preferences;

  DocumentBloc({required IImageRepository repository, required this.preferences})
      : _repository = repository,
        super(const DocumentState()) {
    on<ImageDocumentDelete>(onDeleteImage);
    on<DocumentImageCreateEvent>(onDocumentImageCreate);
    on<GetAllDocumentImage>(getDocumentImage);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  onDeleteImage(ImageDocumentDelete event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteDocument(event.id, getToken());

      emit(state.deleteImage(event.id));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  getDocumentImage(GetAllDocumentImage event, emit) async {
    if (state.results.isNotEmpty) return;

    final token = getToken();
    if (token.isEmpty) return;

    emit(state.copyWith(isLoading: true));
    try {
      var results = await _repository.getDocuments(event.userId, token);
      emit(state.copyWith(isSuccess: true, results: results));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  onDocumentImageCreate(DocumentImageCreateEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.createDocument(
          getToken(), event.photos, event.userId);
      emit(state.copyWith(isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }
}
