import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/core/form_status.dart';
import 'package:optombai/core/import_links.dart';

class ButtonVisibleGate extends StatelessWidget {
  final Widget child;
  final Widget fallback;

  const ButtonVisibleGate({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ButtonVisibleBloc, ButtonVisibleState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.statusChangeMode != current.statusChangeMode ||
          previous.isVisible != current.isVisible,
      builder: (context, bvState) {
        final allowed =
            bvState.status == FormStatus.submissionSuccess && bvState.isVisible;

        return allowed ? child : fallback;
      },
    );
  }
}
