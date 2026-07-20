import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:optombai/core/error/stream_log_file.dart';
import 'package:http/http.dart' as http;

const Map<String, dynamic> _kPeerConnectionConfig = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun.cloudflare.com:3478'},
  ],
  'sdpSemantics': 'unified-plan',
};

class LiveStreamWebRtcPublisher {
  LiveStreamWebRtcPublisher({
    required this.publishApiUrl,
    required this.streamUrl,
  });

  /// SRS publish API endpoint, e.g. `https://optombai.com/rtc/v1/publish/`.
  final String publishApiUrl;

  /// WebRTC stream URL, e.g. `webrtc://optombai.com/live/STREAM_KEY`.
  final String streamUrl;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _audioOnlyStream;
  bool _initialized = false;
  bool _isPublishing = false;
  Timer? _audioStatsTimer;

  dynamic _buildAudioConstraints() {
    // On iOS, complex goog* constraints may yield an attached audio track
    // that never sends RTP. Keep iOS audio constraints minimal.
    if (Platform.isIOS) {
      return true;
    }

    return {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
      'googEchoCancellation': true,
      'googNoiseSuppression': true,
      'googAutoGainControl': true,
      'googHighpassFilter': true,
      'googTypingNoiseDetection': true,
    };
  }

  Map<String, dynamic> _buildMediaConstraints({
    required int width,
    required int height,
    int minFps = 24,
    int maxFps = 30,
  }) {
    return {
      'audio': _buildAudioConstraints(),
      'video': {
        'mandatory': {
          'minWidth': '$width',
          'minHeight': '$height',
          'maxWidth': '$width',
          'maxHeight': '$height',
          'minFrameRate': '$minFps',
          'maxFrameRate': '$maxFps',
        },
        'facingMode': 'user',
        'optional': [],
      },
    };
  }

  Future<MediaStream> _getUserMediaWithFallback() async {
    final profiles = [
      ('720p', _buildMediaConstraints(width: 1280, height: 720)),
      ('540p', _buildMediaConstraints(width: 960, height: 540)),
      ('480p', _buildMediaConstraints(width: 640, height: 480)),
    ];

    Object? lastError;

    for (final (name, constraints) in profiles) {
      try {
        final stream = await navigator.mediaDevices.getUserMedia(constraints);
        StreamLogFile.log('[LS_AUDIO_HOST] camera profile selected: $name');
        return stream;
      } catch (e) {
        lastError = e;
        StreamLogFile.log('[LS_AUDIO_HOST] camera profile failed: $name, error: $e', isWarning: true);
      }
    }

    throw Exception('Failed to getUserMedia for all profiles: $lastError');
  }

  Future<void> init() async {
    if (_initialized) return;
    await localRenderer.initialize();
    try {
      await Helper.ensureAudioSession();
    } catch (_) {}
    if (Platform.isIOS) {
      try {
        await Helper.setAppleAudioIOMode(
          AppleAudioIOMode.localAndRemote,
          preferSpeakerOutput: false,
        );
      } catch (_) {}
    }
    _initialized = true;
  }

  Future<void> start() async {
    if (_isPublishing) return;
    _isPublishing = true;

    try {
      if (!_initialized) await init();

      _localStream = await _getUserMediaWithFallback();
      final audioTracks = _localStream!.getAudioTracks();
      final videoTracks = _localStream!.getVideoTracks();
      StreamLogFile.log('[LS_AUDIO_HOST] local stream ready: audio=${audioTracks.length} video=${videoTracks.length}');
      if (audioTracks.isEmpty) {
        throw Exception('Микрофон не дал audio track');
      }
      for (final track in audioTracks) {
        track.enabled = true;
        try {
          await Helper.setMicrophoneMute(false, track);
        } catch (_) {}
        StreamLogFile.log(
          '[LS_AUDIO_HOST] local audio track state '
          'id=${track.id} enabled=${track.enabled} muted=${track.muted}',
        );
        track.onEnded = () {
          StreamLogFile.log('[LS_AUDIO_HOST_STATS] local audio track ended id=${track.id}', isWarning: true);
        };
      }
      localRenderer.srcObject = _localStream;

      // iOS/SFU edge case: combined getUserMedia(audio+video) may produce
      // an audio track that exists but never sends RTP (outbound stays 0).
      // Capture a dedicated audio-only stream and prefer its track for publish.
      MediaStreamTrack? publishAudioTrack;
      try {
        _audioOnlyStream = await navigator.mediaDevices.getUserMedia({
          'audio': _buildAudioConstraints(),
          'video': false,
        });
        final dedicatedAudioTracks = _audioOnlyStream!.getAudioTracks();
        if (dedicatedAudioTracks.isNotEmpty) {
          publishAudioTrack = dedicatedAudioTracks.first;
          publishAudioTrack.enabled = true;
          try {
            await Helper.setMicrophoneMute(false, publishAudioTrack);
          } catch (_) {}
          StreamLogFile.log(
            '[LS_AUDIO_HOST] Using dedicated audio track '
            'id=${publishAudioTrack.id} enabled=${publishAudioTrack.enabled} muted=${publishAudioTrack.muted}',
          );
        }
      } catch (e) {
        StreamLogFile.log('[LS_AUDIO_HOST] dedicated audio capture failed, fallback to combined stream: $e', isWarning: true);
      }

      publishAudioTrack ??= audioTracks.first;

      _peerConnection = await createPeerConnection(_kPeerConnectionConfig);

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        StreamLogFile.log('[LS_AUDIO_HOST] publisher connection state: $state');
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        StreamLogFile.log('[LS_AUDIO_HOST] publisher ICE state: $state');
      };

      StreamLogFile.log(
        '[LS_AUDIO_HOST] Adding local ${publishAudioTrack.kind} track '
        'id=${publishAudioTrack.id} enabled=${publishAudioTrack.enabled} label=${publishAudioTrack.label}',
      );
      // Use the stream the audio track actually belongs to (avoids msid mismatch in SDP).
      final audioStream = (_audioOnlyStream != null && _audioOnlyStream!.getAudioTracks().contains(publishAudioTrack))
          ? _audioOnlyStream!
          : _localStream!;
      _peerConnection!.addTrack(publishAudioTrack, audioStream);

      for (final track in videoTracks) {
        debugPrint(
          '[LS_AUDIO_HOST] Adding local ${track.kind} track '
          'id=${track.id} enabled=${track.enabled} label=${track.label}',
        );
        _peerConnection!.addTrack(track, _localStream!);
      }

      final senders = await _peerConnection!.getSenders();
      final senderKinds = senders.map((s) => s.track?.kind ?? 'null').toList();
      StreamLogFile.log('[LS_AUDIO_HOST] Sender count=${senders.length} kinds=$senderKinds');

      final RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });

      await _peerConnection!.setLocalDescription(offer);

      final completer = Completer<void>();
      Timer? srflxDebounce;

      // Complete immediately when ICE gathering is fully done.
      _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
          srflxDebounce?.cancel();
          if (!completer.isCompleted) completer.complete();
        }
      };

      // Complete 300 ms after the first public (srflx/relay) candidate arrives.
      // This avoids sending an offer with only unreachable private IPs.
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        final c = candidate.candidate ?? '';
        if (c.contains('srflx') || c.contains('relay')) {
          srflxDebounce?.cancel();
          srflxDebounce = Timer(const Duration(milliseconds: 300), () {
            if (!completer.isCompleted) completer.complete();
          });
        }
      };

      // Hard deadline: 4 s. Enough for STUN on real devices (typically 1–2 s).
      Timer(const Duration(milliseconds: 4000), () {
        srflxDebounce?.cancel();
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;

      final fullOffer = await _peerConnection!.getLocalDescription();
      if (fullOffer == null) throw Exception('Local description is null');
      final sdpContent = fullOffer.sdp ?? '';
      final candidates = sdpContent.split('\n').where((l) => l.startsWith('a=candidate')).toList();
      final hasSrflx = candidates.any((c) => c.contains('srflx') || c.contains('relay'));
      StreamLogFile.log('[LS_AUDIO_HOST] Local SDP: audio=${sdpContent.contains('m=audio')} video=${sdpContent.contains('m=video')} candidates=${candidates.length} hasSrflx=$hasSrflx');
      if (!hasSrflx) {
        StreamLogFile.log('[LS_AUDIO_HOST] WARNING: no srflx/relay candidates — only private IPs. SRS may reject this offer on emulators/restrictive NAT.', isWarning: true);
      }

      StreamLogFile.log('[LS_AUDIO_HOST] sending offer to $publishApiUrl ...');

      final RTCSessionDescription answer = await _sendOfferToServer(fullOffer);
      StreamLogFile.log(
        '[LS_AUDIO_HOST] Remote SDP has audio=${(answer.sdp ?? '').contains('m=audio')} '
        'video=${(answer.sdp ?? '').contains('m=video')}',
      );

      await _peerConnection!.setRemoteDescription(answer);

      StreamLogFile.log('[LS_AUDIO_HOST] connection established');
      _startOutboundAudioStatsLog();
    } catch (e) {
      _isPublishing = false;
      StreamLogFile.log('[LS_AUDIO_HOST] error in start: $e', isWarning: true);
      rethrow;
    }
  }

  void _startOutboundAudioStatsLog() {
    _audioStatsTimer?.cancel();
    _audioStatsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final pc = _peerConnection;
      if (!_isPublishing || pc == null) return;

      try {
        final reports = await pc.getStats();
        for (final report in reports) {
          final type = report.type.toLowerCase();
          if (!type.contains('outbound')) continue;

          final mediaType = (report.values['mediaType'] ?? report.values['kind'] ?? '').toString().toLowerCase();
          if (mediaType != 'audio') continue;

          final packets = report.values['packetsSent'];
          final bytes = report.values['bytesSent'];
          final retransmitted = report.values['retransmittedPacketsSent'];
          final level = report.values['audioLevel'];

          StreamLogFile.log(
            '[LS_AUDIO_HOST_STATS] outbound-audio packets=$packets bytes=$bytes '
            'retransmitted=$retransmitted level=$level id=${report.id}',
          );
        }
      } catch (e) {
        StreamLogFile.log('[LS_AUDIO_HOST_STATS] getStats error: $e', isWarning: true);
      }
    });
  }

  /// Send SDP offer to SRS server using its standard API format.
  Future<RTCSessionDescription> _sendOfferToServer(RTCSessionDescription offer) async {
    final url = Uri.parse(publishApiUrl);

    String formattedSdp = offer.sdp!;

    if (!formattedSdp.contains('\r\n')) {
      formattedSdp = formattedSdp.replaceAll('\n', '\r\n');
    }

    if (formattedSdp.contains('extmap-allow-mixed')) {
      formattedSdp = formattedSdp.split('\r\n').where((line) => !line.contains('extmap-allow-mixed')).join('\r\n');
    }

    final body = jsonEncode({
      'api': publishApiUrl,
      'streamurl': streamUrl,
      'sdp': formattedSdp,
    });

    debugPrint('[LS_AUDIO_HOST] POST $url');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      StreamLogFile.log('[LS_AUDIO_HOST] publish response code=${data['code']}');

      if (data['code'] != 0) {
        StreamLogFile.log('[LS_AUDIO_HOST] PUBLISH ERROR: SRS code=${data['code']} full response: ${response.body}', isWarning: true);
        throw Exception('SRS error code: ${data['code']}');
      }

      final sdpAnswer = data['sdp'];
      debugPrint('[LS_AUDIO_HOST] Publish answer length=${sdpAnswer?.toString().length ?? 0}');
      return RTCSessionDescription(sdpAnswer, 'answer');
    } else {
      StreamLogFile.log('[LS_AUDIO_HOST] PUBLISH ERROR: HTTP ${response.statusCode} body: ${response.body}', isWarning: true);
      throw Exception('Http Error: ${response.statusCode}');
    }
  }

  Future<void> stop() async {
    _isPublishing = false;
    await _cleanup();
  }

  Future<void> _cleanup() async {
    _audioStatsTimer?.cancel();
    _audioStatsTimer = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    _localStream = null;

    _audioOnlyStream?.getTracks().forEach((t) => t.stop());
    await _audioOnlyStream?.dispose();
    _audioOnlyStream = null;

    await _peerConnection?.close();
    _peerConnection = null;
  }

  Future<void> dispose() async {
    await stop();
    await localRenderer.dispose();
  }
}
