part of 'image_bloc.dart';

@immutable
abstract class ImageEvent extends Equatable {}

class ImageCreateEvent extends ImageEvent {
  final String userId;
  final File photos;

  ImageCreateEvent({required this.userId, required this.photos});

  @override
  List<Object?> get props => [];
}

class GetAllImage extends ImageEvent {
  final String userId;

  GetAllImage(this.userId, );

  @override
  List<Object?> get props => [userId];
}


class ImageDelete extends ImageEvent {
  final int id;

  ImageDelete({required this.id});

  @override
  List<Object?> get props => [id];
}
