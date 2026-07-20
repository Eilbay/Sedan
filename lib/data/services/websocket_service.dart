import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:optombai/data/models/chat/message_model.dart';

/// Domain error emitted by the chat WebSocket — distinct from transport-level
/// errors. Currently the only producer is the backend BLOCKED rejection.
class ChatWsError {
  final String code;
  final String detail;

  const ChatWsError({required this.code, required this.detail});
}

/// Read receipt pushed over the chat WebSocket when the other participant reads
/// messages. [messageIds] empty means "all messages in this chat were read".
class ChatReadReceipt {
  final List<String> messageIds;

  const ChatReadReceipt({this.messageIds = const []});
}

class WebSocketService {
  WebSocketService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  WebSocketChannel? _channel;
  StreamController<Message>? _messageController;
  StreamController<ChatWsError>? _errorController;
  StreamController<ChatReadReceipt>? _readController;
  StreamSubscription? _subscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _chatId;
  String? _token;
  bool _isConnected = false;

  /// True between [connect] and [disconnect]: gates every reconnect path so a
  /// teardown can never be revived by a late timer or connectivity event.
  bool _wantConnected = false;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _baseDelaySeconds = 3;
  static const int _maxDelaySeconds = 48;

  Stream<Message> get messageStream => _messageController!.stream;

  Stream<ChatWsError> get errorStream => _errorController!.stream;

  Stream<ChatReadReceipt> get readStream => _readController!.stream;

  bool get isConnected => _isConnected;

  void connect(String chatId, String token) {
    _chatId = chatId;
    _token = token;
    _wantConnected = true;
    _reconnectAttempts = 0;

    _messageController ??= StreamController<Message>.broadcast();
    _errorController ??= StreamController<ChatWsError>.broadcast();
    _readController ??= StreamController<ChatReadReceipt>.broadcast();

    // Revive the socket the moment connectivity returns — instead of hammering
    // DNS on a fixed timer while the device is offline.
    _connectivitySub ??=
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    _open();
  }

  void _open() {
    if (!_wantConnected || _chatId == null || _token == null) return;

    _teardownChannel();

    try {
      final wsUrl =
          Uri.parse('wss://optombai.com/ws/chat/$_chatId/?token=$_token');
      final channel = WebSocketChannel.connect(wsUrl);
      _channel = channel;

      _subscription = channel.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // `ready` is the only deterministic "the socket actually opened" signal.
      // Resetting the attempt counter here (not in connect) is what stops the
      // infinite reconnect loop: a failed connect no longer wipes the budget.
      // Consuming the rejection also keeps the transport error from escaping
      // to the zone handler and flooding the crash log.
      channel.ready.then((_) {
        if (!_wantConnected) return;
        _isConnected = true;
        _reconnectAttempts = 0;
        _startHeartbeat();
        debugPrint('[WebSocket] Connected to chat $_chatId');
      }).catchError((Object e) {
        debugPrint('[WebSocket] Connect failed: $e');
        _isConnected = false;
        _scheduleReconnect();
      });
    } catch (e) {
      debugPrint('[WebSocket] Connection error: $e');
      _scheduleReconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      try {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        debugPrint('[WebSocket] Heartbeat failed: $e');
        _scheduleReconnect();
      }
    });
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data);
      if (json is! Map) return;

      final type = (json['type'] ?? '').toString().toLowerCase();

      if (type == 'error') {
        final error = ChatWsError(
          code: (json['code'] ?? '') as String,
          detail: (json['detail'] ?? '') as String,
        );
        _errorController?.add(error);
        debugPrint('[WebSocket] Domain error: ${error.code}');
        return;
      }

      // Read receipt: the backend signals it via an event type that contains
      // "read" (e.g. read / read_receipt / messages_read) or equals "seen".
      // A normal chat message's `type` is text/image/video/file, so there is
      // no collision. The id list is optional — absent means "all read".
      if (type.contains('read') || type == 'seen') {
        _readController?.add(ChatReadReceipt(messageIds: _extractIds(json)));
        debugPrint('[WebSocket] Read receipt: type=$type');
        return;
      }

      final message = Message.fromJson(json as Map<String, dynamic>);
      // Frames without an id are not chat messages (system / unknown events) —
      // dropping them avoids inserting an empty bubble into the conversation.
      if (message.id.isEmpty) {
        debugPrint('[WebSocket] Ignored non-message frame: type=$type');
        return;
      }
      _messageController?.add(message);
      debugPrint('[WebSocket] Message received: ${message.id}');
    } catch (e) {
      debugPrint('[WebSocket] Failed to parse payload: $e');
    }
  }

  /// Extract message ids from a read-receipt frame, tolerating the common key
  /// names backends use. Returns an empty list when none are present.
  List<String> _extractIds(Map json) {
    final raw = json['message_ids'] ?? json['ids'] ?? json['read_message_ids'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final single = json['message_id'] ?? json['id'];
    if (single != null && single.toString().isNotEmpty) {
      return [single.toString()];
    }
    return const [];
  }

  void _onError(error) {
    debugPrint('[WebSocket] Error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WebSocket] Connection closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_wantConnected) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      // Give up the timer-driven loop; the connectivity listener will revive
      // the socket with a fresh budget once the network is back.
      debugPrint('[WebSocket] Max reconnect attempts reached — awaiting network');
      return;
    }

    _reconnectTimer?.cancel();
    final delaySeconds =
        (_baseDelaySeconds << _reconnectAttempts).clamp(
      _baseDelaySeconds,
      _maxDelaySeconds,
    );
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (!_wantConnected) return;

      // Don't burn the attempt budget hammering DNS while offline — defer to
      // the connectivity listener, which fires the instant the network returns.
      final results = await _connectivity.checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) {
        debugPrint('[WebSocket] Offline — deferring reconnect to connectivity');
        return;
      }

      _reconnectAttempts++;
      debugPrint('[WebSocket] Reconnecting... (attempt $_reconnectAttempts)');
      _open();
    });
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (_wantConnected && hasNetwork && !_isConnected) {
      debugPrint('[WebSocket] Network restored — reconnecting');
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _open();
    }
  }

  /// Closes the live channel and its timers but keeps the broadcast controllers
  /// and the connectivity subscription alive, so a reconnect is transparent to
  /// existing listeners.
  void _teardownChannel() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void disconnect() {
    _wantConnected = false;
    _reconnectAttempts = 0;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _teardownChannel();
    debugPrint('[WebSocket] Disconnected');
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
    _errorController?.close();
    _errorController = null;
    _readController?.close();
    _readController = null;
  }
}
