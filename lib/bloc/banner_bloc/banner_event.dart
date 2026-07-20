part of 'banner_bloc.dart';

sealed class BannerEvent extends Equatable {
  const BannerEvent();
}

class BannerAllEvent extends BannerEvent {
  final bool forceRefresh;

  const BannerAllEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}
