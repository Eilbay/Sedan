import 'package:optombai/bloc/feature_flags_cubit/feature_flags_cubit.dart';
import 'package:optombai/core/form_status.dart';
import 'package:optombai/core/import_links.dart';

/// Shows [child] only while the server has [flagKey] enabled under
/// `featureFlags/`. Use this to hide a button/section without an app
/// release, the same way [ButtonVisibleGate] gates the "Тарифы" entry.
class FeatureFlagGate extends StatelessWidget {
  final String flagKey;
  final Widget child;
  final Widget fallback;

  const FeatureFlagGate({
    super.key,
    required this.flagKey,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureFlagsCubit, FeatureFlagsState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isVisible(flagKey) != current.isVisible(flagKey),
      builder: (context, state) {
        final allowed = state.status == FormStatus.submissionSuccess &&
            state.isVisible(flagKey);

        return allowed ? child : fallback;
      },
    );
  }
}
