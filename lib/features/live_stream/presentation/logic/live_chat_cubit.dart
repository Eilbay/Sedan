import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/stream_log_file.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatMessage {
  final String username;
  final String userId;
  final String message;
  final String? avatarUrl;

  const ChatMessage(
    this.username,
    this.message, {
    this.userId = '',
    this.avatarUrl,
  });
}

class ChatParticipant {
  final String userId;
  final String username;
  final String? avatarUrl;

  const ChatParticipant({
    required this.userId,
    required this.username,
    this.avatarUrl,
  });
}

class LiveChatState {
  const LiveChatState({
    this.messages = const [],
    this.error,
    this.isConnected = false,
    this.viewerCount = 0,
    this.isBanned = false,
    this.banDurationLabel,
    this.participants = const {},
    this.streamEnded = false,
    this.endReason,
  });

  final List<ChatMessage> messages;
  final String? error;
  final bool isConnected;
  final int viewerCount;
  final bool isBanned;

  /// Human-readable ban duration received from server, e.g. "1 час", "24 часа".
  /// Null if server didn't send duration info.
  final String? banDurationLabel;

  /// Users currently watching the stream — keyed by userId.
  /// Populated from `join`/`exit` WS events, and also from `chat.message`
  /// senders as a fallback for viewers who joined before this client connected.
  final Map<String, ChatParticipant> participants;

  /// Set once the server reports the broadcast is over — either via a
  /// `stream.ended` message or WS close code 4404.
  final bool streamEnded;

  /// Raw `reason` from the `stream.ended` payload/close code, e.g.
  /// "manual", "disconnect", "timeout", "superseded", "admin".
  final String? endReason;

  LiveChatState copyWith({
    List<ChatMessage>? messages,
    String? error,
    bool? isConnected,
    int? viewerCount,
    bool? isBanned,
    String? banDurationLabel,
    Map<String, ChatParticipant>? participants,
    bool? streamEnded,
    String? endReason,
  }) {
    return LiveChatState(
      messages: messages ?? this.messages,
      error: error,
      isConnected: isConnected ?? this.isConnected,
      viewerCount: viewerCount ?? this.viewerCount,
      isBanned: isBanned ?? this.isBanned,
      banDurationLabel: banDurationLabel ?? this.banDurationLabel,
      participants: participants ?? this.participants,
      streamEnded: streamEnded ?? this.streamEnded,
      endReason: endReason ?? this.endReason,
    );
  }
}

/// Manages WebSocket connection and message handling for live chat.
class LiveChatCubit extends Cubit<LiveChatState> {
  LiveChatCubit({
    required this.streamUuid,
    required this.token,
    int initialViewerCount = 0,
  }) : super(LiveChatState(viewerCount: initialViewerCount));

  static const int _maxMessages = 200;
  // WS close code sent by server when viewer is banned from the stream.
  static const int _bannedCloseCode = 4403;
  // WS close code sent by server when the broadcast itself is over.
  static const int _streamEndedCloseCode = 4404;

  final String streamUuid;
  final String token;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  void connect() {
    // Do not reconnect if already banned.
    if (state.isBanned) return;

    disconnect();

    try {
      final uri = Uri(
        scheme: 'wss',
        host: 'optombai.com',
        path: '/ws/streams/$streamUuid/',
        queryParameters: {'token': token},
      );

      StreamLogFile.log(
          '[LS_CHAT] connecting stream=$streamUuid tokenPresent=${token.isNotEmpty}');

      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 15),
      );

      _sub = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      emit(state.copyWith(isConnected: true));
    } catch (e) {
      StreamLogFile.log('[LS_CHAT] connect threw: $e', isWarning: true);
      if (!isClosed) {
        emit(state.copyWith(error: e.toString(), isConnected: false));
      }
    }
  }

  void send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      _channel?.sink.add(jsonEncode({'message': trimmed}));
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return;

      final type = data['type']?.toString() ?? '';

      if (type == 'chat.message') {
        final user = data['user'];
        final userData = user is Map ? user : null;
        final username = (userData?['username'] ??
                userData?['name'] ??
                data['username'] ??
                user ??
                'Пользователь')
            .toString();
        final userId = (userData?['id'] ?? data['user_id'] ?? '').toString();
        final message = (data['message'] ?? '').toString();
        final rawAvatar = userData?['avatar'] ??
            userData?['image'] ??
            userData?['user_image'] ??
            data['avatar'] ??
            data['image'] ??
            data['user_image'] ??
            data['profile_image'];
        final avatarUrl = rawAvatar?.toString().trim();

        final updated = List<ChatMessage>.from(state.messages)
          ..add(ChatMessage(
            username,
            message,
            userId: userId,
            avatarUrl:
                avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
          ));

        if (updated.length > _maxMessages) {
          updated.removeAt(0);
        }

        Map<String, ChatParticipant>? updatedParticipants;
        if (userId.isNotEmpty) {
          updatedParticipants =
              Map<String, ChatParticipant>.from(state.participants);
          updatedParticipants[userId] = ChatParticipant(
            userId: userId,
            username: username,
            avatarUrl:
                avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
          );
        }

        if (!isClosed) {
          emit(state.copyWith(
            messages: updated,
            participants: updatedParticipants,
          ));
        }
      } else if (type == 'viewers') {
        final count = data['viewers'];
        if (count != null && !isClosed) {
          final parsed = count is int
              ? count
              : int.tryParse(count.toString()) ?? state.viewerCount;
          emit(state.copyWith(viewerCount: parsed));
        }
      } else if (type == 'join') {
        final participant = _parseParticipant(data['user']);
        if (participant != null && !isClosed) {
          final updated = Map<String, ChatParticipant>.from(state.participants);
          updated[participant.userId] = participant;
          emit(state.copyWith(participants: updated));
        }
      } else if (type == 'exit') {
        final participant = _parseParticipant(data['user']);
        if (participant != null &&
            !isClosed &&
            state.participants.containsKey(participant.userId)) {
          final updated = Map<String, ChatParticipant>.from(state.participants)
            ..remove(participant.userId);
          emit(state.copyWith(participants: updated));
        }
      } else if (type == 'stream.ban' || type == 'ban') {
        // Server sends ban details before closing with code 4403.
        // Expected payload: {"type": "stream.ban", "minutes": 60}
        final minutes = data['minutes'];
        final label = _parseBanDuration(minutes);
        StreamLogFile.log(
            '[LS_CHAT] ban message received stream=$streamUuid minutes=$minutes',
            isWarning: true);
        if (!isClosed) {
          emit(state.copyWith(banDurationLabel: label));
        }
      } else if (type == 'stream.ended') {
        // Server sends this before closing with code 4404, e.g.
        // {"type": "stream.ended", "reason": "manual", "stream_id": "..."}
        final reason = data['reason']?.toString();
        StreamLogFile.log(
            '[LS_CHAT] stream.ended received stream=$streamUuid reason=$reason');
        if (!isClosed) {
          emit(state.copyWith(streamEnded: true, endReason: reason));
        }
      } else {
        // Diagnostic: capture any WS event type not yet handled by the
        // client (e.g. a viewer-list/join event) so we can confirm the
        // server contract before wiring up a full viewer list.
        talker.info('[LIVE_CHAT_WS] unhandled type="$type" payload=$data');
      }
    } catch (e) {
      talker.info('[LIVE_CHAT_WS] failed to parse message: $raw error=$e');
    }
  }

  void _onError(Object e) {
    StreamLogFile.log('[LS_CHAT] WS error stream=$streamUuid: $e',
        isWarning: true);
    if (isClosed) return;
    // A real ban is only ever signalled by the server closing the socket
    // with code 4403 (handled in `_onDone`). Treating any error whose
    // message happened to contain the substring "403" as a ban was wrong —
    // an unrelated handshake failure (network hiccup, wrong WS URL, etc.)
    // could match and incorrectly kick a viewer out with a "you are banned"
    // dialog even though they were never banned.
    emit(state.copyWith(error: e.toString(), isConnected: false));
  }

  void _onDone() {
    if (isClosed) return;
    final code = _channel?.closeCode;
    final reason = _channel?.closeReason ?? '';
    final isBanned = code == _bannedCloseCode;
    // The `stream.ended` message usually arrives just before this close, but
    // fall back to the close code alone in case the message was dropped.
    final streamEnded = state.streamEnded || code == _streamEndedCloseCode;

    StreamLogFile.log(
        '[LS_CHAT] WS closed stream=$streamUuid code=$code reason="$reason" '
        'banned=$isBanned streamEnded=$streamEnded',
        isWarning: isBanned);

    // If we already have a duration from a stream.ban WS message, keep it.
    // Otherwise try to parse minutes from the close reason string.
    String? durationLabel = state.banDurationLabel;
    if (durationLabel == null && isBanned && reason.isNotEmpty) {
      final match = RegExp(r'(\d+)').firstMatch(reason);
      if (match != null) {
        durationLabel = _parseBanDuration(int.tryParse(match.group(1) ?? ''));
      }
    }

    emit(state.copyWith(
      isConnected: false,
      isBanned: isBanned,
      banDurationLabel: durationLabel,
      streamEnded: streamEnded,
    ));
  }

  /// Parses the `user` object sent with `join`/`exit` WS events into a
  /// [ChatParticipant]. Returns null if the payload has no user id.
  static ChatParticipant? _parseParticipant(dynamic user) {
    if (user is! Map) return null;

    final userId = (user['id'] ?? '').toString();
    if (userId.isEmpty) return null;

    final username =
        (user['username'] ?? user['name'] ?? 'Пользователь').toString();
    final rawAvatar = user['avatar'] ?? user['image'] ?? user['user_image'];
    final avatarUrl = rawAvatar?.toString().trim();

    return ChatParticipant(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
    );
  }

  /// Converts minutes into a human-readable Russian label.
  static String? _parseBanDuration(dynamic minutes) {
    if (minutes == null) return null;
    final mins = minutes is int ? minutes : int.tryParse(minutes.toString());
    if (mins == null) return null;
    if (mins >= 525600) return 'навсегда'; // ~1 year = permanent
    if (mins >= 1440) {
      final days = mins ~/ 1440;
      return '$days ${_dayWord(days)}';
    }
    if (mins >= 60) {
      final hours = mins ~/ 60;
      return '$hours ${_hourWord(hours)}';
    }
    return '$mins мин.';
  }

  static String _hourWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'час';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'часа';
    }
    return 'часов';
  }

  static String _dayWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'дня';
    }
    return 'дней';
  }

  @override
  Future<void> close() {
    disconnect();
    return super.close();
  }
}
