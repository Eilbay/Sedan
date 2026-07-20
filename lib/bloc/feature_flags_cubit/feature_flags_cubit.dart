import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:optombai/core/form_status.dart';
import 'package:optombai/firebase/service.dart';

part 'feature_flags_state.dart';

/// Holds every remotely-controlled feature-visibility flag behind one
/// Firebase listener. Hiding a button from the server needs only a new
/// child key under `featureFlags/` — no new Bloc/Cubit class per flag,
/// mirroring the existing isButtonVisible mechanism in [FirebaseService].
class FeatureFlagsCubit extends Cubit<FeatureFlagsState> {
  final FirebaseService _firebaseService;
  StreamSubscription<Map<String, bool>>? _subscription;

  FeatureFlagsCubit(this._firebaseService) : super(const FeatureFlagsState());

  Future<void> load() async {
    try {
      final flags = await _firebaseService.getFeatureFlags();
      emit(state.copyWith(status: FormStatus.submissionSuccess, flags: flags));

      _subscription = _firebaseService.listenToFeatureFlags().listen((flags) {
        emit(
          state.copyWith(status: FormStatus.submissionSuccess, flags: flags),
        );
      });
    } catch (e) {
      emit(
        state.copyWith(
          status: FormStatus.submissionFailure,
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
