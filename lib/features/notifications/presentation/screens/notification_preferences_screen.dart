import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/features/notifications/presentation/logic/notifications_cubit.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

@RoutePage()
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsCubit>().loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TextTranslated('Настройки уведомлений'),
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        buildWhen: (p, c) =>
            p.preferences != c.preferences ||
            p.isUpdatingPreferences != c.isUpdatingPreferences,
        builder: (context, state) {
          final prefs = state.preferences;
          if (prefs == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              _PrefSwitchTile(
                title: 'Лайки',
                subtitle: 'Когда кто-то поставил лайк вашему товару',
                value: prefs.likesEnabled,
                isUpdating: state.isUpdatingPreferences,
                onChanged: (v) => context
                    .read<NotificationsCubit>()
                    .updatePreferences({'likes_enabled': v}),
              ),
              _PrefSwitchTile(
                title: 'Комментарии',
                subtitle: 'Новые комментарии к вашим товарам',
                value: prefs.commentsEnabled,
                isUpdating: state.isUpdatingPreferences,
                onChanged: (v) => context
                    .read<NotificationsCubit>()
                    .updatePreferences({'comments_enabled': v}),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrefSwitchTile extends StatelessWidget {
  const _PrefSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isUpdating,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: TextTranslated(title),
      subtitle: TextTranslated(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      onChanged: isUpdating ? null : onChanged,
    );
  }
}
