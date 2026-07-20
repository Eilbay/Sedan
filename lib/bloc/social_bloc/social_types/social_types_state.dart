part of 'social_types_bloc.dart';

class SocialTypesState extends Equatable {
  final List<SocialType> socialsTypes;
  final List<String> errors;
  final List<SocialOwner> socialOwner;

  const SocialTypesState(
      {this.socialsTypes = const [], this.errors = const [],this.socialOwner = const []});

  @override
  List<Object?> get props => [socialsTypes, errors,socialOwner];

  SocialTypesState copyWith(
      {List<SocialType>? socialsTypes, List<String> errors = const [],List<SocialOwner>? socialOwner,}) {
    return SocialTypesState(
        socialsTypes: socialsTypes ?? this.socialsTypes, errors: errors, socialOwner: socialOwner ?? this.socialOwner);
  }
}
