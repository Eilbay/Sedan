class Streams {
  final dynamic next;
  final dynamic previous;
  final List<StreamModel> results;

  Streams({
    required this.next,
    required this.previous,
    required this.results,
  });

  factory Streams.fromJson(Map<String, dynamic> map) {
    final rawResults = map['results'];
    final list = rawResults is List ? rawResults : const <dynamic>[];

    return Streams(
      next: map['next'],
      previous: map['previous'],
      results: List<StreamModel>.from(
        list.map(
          (x) => StreamModel.fromJson(
            x is Map<String, dynamic> ? x : Map<String, dynamic>.from(x as Map),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'next': next,
      'previous': previous,
      'results': results.map((stream) => stream.toJson()).toList(),
    };
  }
}

/// Defensive client-side enforcement of the product invariant that one owner
/// can have only one live broadcast. The backend remains the source of truth,
/// but older ghost rows must not create duplicate pages and peer connections.
/// The newest started stream wins; response order is retained for owners.
Streams deduplicateStreamsByOwner(Streams streams) {
  final byOwner = <String, StreamModel>{};

  for (final stream in streams.results) {
    final ownerId = stream.owner.id.trim();
    final key = ownerId.isEmpty ? 'stream:${stream.id}' : 'owner:$ownerId';
    final current = byOwner[key];

    if (current == null || _isNewerStream(stream, current)) {
      byOwner[key] = stream;
    }
  }

  return Streams(
    next: streams.next,
    previous: streams.previous,
    results: byOwner.values.toList(growable: false),
  );
}

bool _isNewerStream(StreamModel candidate, StreamModel current) {
  final candidateStartedAt = candidate.startedAt;
  final currentStartedAt = current.startedAt;

  if (candidateStartedAt == null) return false;
  if (currentStartedAt == null) return true;
  return candidateStartedAt.isAfter(currentStartedAt);
}

class StreamModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final bool isLive;
  final int viewers;
  final DateTime? startedAt;
  final dynamic endedAt;
  final String streamKey;
  final String hlsUrl;
  final Webrtc webrtc;
  final Chat chat;
  final Owner owner;

  /// WHEP/WebRTC play endpoint, derived from [webrtc]'s host — same host as
  /// the signalling URL, fixed `/rtc/v1/play/` path.
  String get playApiUrl {
    final uri = Uri.tryParse(webrtc.url.replaceFirst('webrtc://', 'https://'));
    final host = uri?.host ?? 'optombai.com';
    return 'https://$host/rtc/v1/play/';
  }

  StreamModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.isLive,
    required this.owner,
    this.startedAt,
    required this.endedAt,
    required this.streamKey,
    required this.hlsUrl,
    required this.webrtc,
    required this.chat,
    required this.viewers,
  });

  factory StreamModel.fromJson(Map<String, dynamic> map) {
    final ownerMap = _asMap(map['owner']);
    final webrtcMap = _asMap(map['webrtc']);
    final chatMap = _asMap(map['chat']);

    return StreamModel(
      id: _asString(map['id']),
      type: _asString(map['type']),
      title: _asString(map['title']),
      description: _asString(map['description']),
      isLive: _asBool(map['is_live']),
      viewers: _asInt(map['viewers']),
      owner: Owner.fromJson(ownerMap),
      startedAt: _parseDateTime(map['started_at']),
      endedAt: map['ended_at'] as dynamic,
      streamKey: _asString(map['stream_key']),
      hlsUrl: _asString(map['hls_url']),
      webrtc: Webrtc.fromJson(webrtcMap),
      chat: Chat.fromJson(chatMap),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'is_live': isLive,
      'viewers': viewers,
      'owner': owner.toJson(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt,
      'stream_key': streamKey,
      'hls_url': hlsUrl,
      'webrtc': webrtc.toJson(),
      'chat': chat.toJson(),
    };
  }
}

class Chat {
  final String wsUrl;
  final String wsUrlWithTokenTemplate;

  Chat({
    required this.wsUrl,
    required this.wsUrlWithTokenTemplate,
  });

  factory Chat.fromJson(Map<String, dynamic> map) {
    return Chat(
      wsUrl: _asString(map['ws_url']),
      wsUrlWithTokenTemplate: _asString(map['ws_url_with_token_template']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ws_url': wsUrl,
      'ws_url_with_token_template': wsUrlWithTokenTemplate,
    };
  }
}

class Owner {
  final String id;
  final String username;
  final String? image;
  final bool isVerified;
  final String? countryName;
  final String? countryFlag;
  final String? marketName;

  Owner({
    required this.id,
    required this.username,
    this.image,
    this.isVerified = false,
    this.countryName,
    this.countryFlag,
    this.marketName,
  });

  factory Owner.fromJson(Map<String, dynamic> map) {
    final country = _asMap(map['country']);

    return Owner(
      id: _asString(map['id']),
      username: _asString(map['username']),
      image: _nullableString(map['image']),
      isVerified:
          _asBool(map['is_verified']) || _asBool(map['account_verified']),
      countryName:
          _nullableString(country['name']) ?? _nullableString(country['title']),
      countryFlag: _nullableString(country['square_flag']) ??
          _nullableString(country['flag']),
      marketName: _extractFirstMarketName(map),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'image': image,
      'is_verified': isVerified,
      'country': {
        'name': countryName,
        'square_flag': countryFlag,
      },
      'supplier': marketName == null
          ? const []
          : [
              {
                'market': {'name': marketName}
              }
            ],
    };
  }
}

String? _nullableString(dynamic value) {
  final parsed = _asString(value).trim();
  return parsed.isEmpty ? null : parsed;
}

String? _extractFirstMarketName(Map<String, dynamic> map) {
  final rawSuppliers = map['suppliers'] ?? map['supplier'];
  if (rawSuppliers is! List || rawSuppliers.isEmpty) return null;

  for (final item in rawSuppliers) {
    final supplier = _asMap(item);
    final market = _asMap(supplier['market']);
    final marketName = _nullableString(market['name']) ??
        _nullableString(supplier['market_name']);
    if (marketName != null) {
      return marketName;
    }
  }

  return null;
}

class Webrtc {
  final String apiUrl;
  final WebrtcApi api;
  final String app;
  final String stream;
  final String url;

  Webrtc({
    required this.apiUrl,
    required this.api,
    required this.app,
    required this.stream,
    required this.url,
  });

  factory Webrtc.fromJson(Map<String, dynamic> map) {
    final apiMap = _asMap(map['api']);

    return Webrtc(
      apiUrl: _asString(map['api_url']),
      api: WebrtcApi.fromJson(apiMap),
      app: _asString(map['app']),
      stream: _asString(map['stream']),
      url: _asString(map['url']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'api_url': apiUrl,
      'api': api.toJson(),
      'app': app,
      'stream': stream,
      'url': url,
    };
  }
}

class WebrtcApi {
  final String play;
  final String publish;

  WebrtcApi({
    required this.play,
    required this.publish,
  });

  factory WebrtcApi.fromJson(Map<String, dynamic> map) {
    return WebrtcApi(
      play: _asString(map['play']),
      publish: _asString(map['publish']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'play': play,
      'publish': publish,
    };
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _asString(dynamic value) => value?.toString() ?? '';

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
