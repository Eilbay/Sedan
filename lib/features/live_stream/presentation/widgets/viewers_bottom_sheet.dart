import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/features/live_stream/presentation/logic/live_chat_cubit.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_ban_cubit.dart';
import 'package:optombai/features/live_stream/presentation/widgets/ban_user_bottom_sheet.dart';

class ViewersBottomSheet extends StatelessWidget {
  static Future<void> show(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<LiveChatCubit>()),
          BlocProvider.value(value: context.read<StreamBanCubit>()),
        ],
        child: ViewersBottomSheet._internal(messenger: messenger),
      ),
    );
  }

  const ViewersBottomSheet._internal({required this.messenger});

  final ScaffoldMessengerState messenger;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BlocBuilder<LiveChatCubit, LiveChatState>(
              buildWhen: (prev, cur) => prev.viewerCount != cur.viewerCount,
              builder: (_, state) {
                // The server's viewer count always includes the host's own
                // open connection — subtract it so the badge matches the
                // participants list below, which already excludes the host.
                final displayedCount =
                    state.viewerCount > 0 ? state.viewerCount - 1 : 0;
                return Row(
                  children: [
                    Text(
                      'Зрители',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF004D).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$displayedCount',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF004D),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<LiveChatCubit, LiveChatState>(
            buildWhen: (prev, cur) => prev.participants != cur.participants,
            builder: (ctx, state) {
              final currentUserId = ctx.read<UserBloc>().state.user.id;
              final participants = state.participants.values
                  .where((p) => p.userId != currentUserId)
                  .toList();

              if (participants.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 40, color: subtitleColor),
                      const SizedBox(height: 8),
                      Text(
                        'Пока никто не смотрит',
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  shrinkWrap: true,
                  itemCount: participants.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 68,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  itemBuilder: (_, i) => _ParticipantTile(
                    participant: participants[i],
                    messenger: messenger,
                    isDark: isDark,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    required this.messenger,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
  });

  final ChatParticipant participant;
  final ScaffoldMessengerState messenger;
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: isDark ? Colors.white12 : const Color(0xFFF0F0F0),
        backgroundImage: participant.avatarUrl != null
            ? CachedNetworkImageProvider(participant.avatarUrl!)
            : null,
        child: participant.avatarUrl == null
            ? Text(
                participant.username.isNotEmpty
                    ? participant.username[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              )
            : null,
      ),
      title: Text(
        participant.username,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          BanUserBottomSheet.show(
            context,
            username: participant.username,
            userId: participant.userId,
            messenger: messenger,
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFF004D),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: const Text(
          'Забанить',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
