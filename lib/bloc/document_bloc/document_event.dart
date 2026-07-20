part of 'document_bloc.dart';



@immutable
abstract class DocumentEvent extends Equatable {}

class DocumentImageCreateEvent extends DocumentEvent {
  final String userId;
  final File photos;

  DocumentImageCreateEvent({required this.userId, required this.photos});

  @override
  List<Object?> get props => [];
}

class GetAllDocumentImage extends DocumentEvent {
  final String userId;

  GetAllDocumentImage(this.userId);


  @override
  List<Object?> get props => [userId];
}


class ImageDocumentDelete extends DocumentEvent {
  final int id;

  ImageDocumentDelete({required this.id});

  @override
  List<Object?> get props => [id];
}


