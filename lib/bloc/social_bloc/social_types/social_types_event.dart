part of 'social_types_bloc.dart';

abstract class SocialTypesEvent extends Equatable {
  const SocialTypesEvent();
}

class SocialsGetEvent extends SocialTypesEvent {
  @override
  List<Object?> get props => [];
}
class SocialsGet extends SocialTypesEvent {
 late final  String id;
  @override
  List<Object?> get props => [id];
}