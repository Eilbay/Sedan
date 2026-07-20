part of 'banner_bloc.dart';

sealed class BannerState extends Equatable{
  const BannerState();
}

final class BannerInitial extends BannerState {
  @override
  List<Object> get props => [];
}

final class BannerLoading extends BannerState {
  @override
  List<Object> get props => [];
}

final class BannerError extends BannerState {
  @override
  List<Object> get props => [];
}

final class BannerSuccess extends BannerState {
  final List<BannerModel> list;

  const BannerSuccess(this.list);

  @override
  List<Object> get props => [list];
}