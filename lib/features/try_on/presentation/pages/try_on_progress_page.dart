import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/features/try_on/presentation/bloc/try_on_cubit.dart';
import 'package:optombai/features/try_on/presentation/bloc/try_on_state.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class TryOnProgressPage extends StatelessWidget {
  const TryOnProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TryOnCubit, TryOnState>(
      listenWhen: (p, n) => p.resultUrl != n.resultUrl || p.error != n.error,
      listener: (ctx, s) {
        if (s.error != null) {
          ctx.router.maybePop();
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(s.error!)),
          );
        } else if (s.resultUrl != null) {
          ctx.router.replace(TryOnResultRoute(
            imageUrl: s.resultUrl!.toString(),
          ));
        }
      },
      builder: (ctx, s) {
        final progress = (s.task?.progress ?? 0).clamp(0, 100);
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.75),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.checkroom, size: 40),
                        const SizedBox(height: 12),
                        const Text('Одеваем вас…',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress / 100.0,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('$progress%',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                          s.task?.status.name.toUpperCase() ?? 'В процессе',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Не закрывайте экран до окончания.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
