part of 'update_cubit.dart';

class UpdateState extends Equatable {
  const UpdateState({
    this.info = AppUpdateInfo.none,
    this.dismissed = false,
  });

  final AppUpdateInfo info;
  final bool dismissed;

  bool get showHardGate => info.type == UpdateType.hard;
  bool get showSoftGate => info.type == UpdateType.soft && !dismissed;

  UpdateState copyWith({AppUpdateInfo? info, bool? dismissed}) {
    return UpdateState(
      info: info ?? this.info,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  @override
  List<Object?> get props => [info.type, info.storeUrl, dismissed];
}
