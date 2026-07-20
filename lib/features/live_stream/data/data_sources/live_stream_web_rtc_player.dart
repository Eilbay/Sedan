import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:optombai/core/error/stream_log_file.dart';
import 'package:http/http.dart' as http;

class LiveStreamWebRtcPlayer {
  LiveStreamWebRtcPlayer({
    required this.playApiUrl,
    required this.streamUrl,
    this.onStreamEnded,
  });

  /// SRS play API endpoint, e.g. `https://optombai.com/rtc/v1/play/`.
  final String playApiUrl;

  /// WebRTC stream URL, e.g. `webrtc://optombai.com/live/STREAM_KEY`.
  final String streamUrl;

  final VoidCallback? onStreamEnded;

  final RTCVideoRenderer renderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  bool _isPlaying = false;
  bool _isDisposed = false;
  Timer? _audioStatsTimer;
  Timer? _disconnectGraceTimer;

  // SRS/flutter_webrtc fires onTrack once per media type, each with its own
  // single-track MediaStream (audio, then video). Only the VIDEO stream gets
  // attached to the renderer; audio tracks are held directly so callers can
  // toggle them without depending on what the renderer carries.
  final List<MediaStreamTrack> _audioTracks = [];

  /// Enable/disable every received remote audio track directly — does not
  /// depend on `renderer.srcObject`, which only needs to carry the video
  /// track for display.
  void setAudioEnabled(bool enabled) {
    for (final track in _audioTracks) {
      track.enabled = enabled;
    }
    StreamLogFile.log(
      '[LS_AUDIO_VIEWER_STATE] setAudioEnabled($enabled) tracks=${_audioTracks.length}',
    );
  }

  /// ICE/peer "disconnected" is a transient state that often self-recovers
  /// (brief network hiccup, app backgrounding, a heavy UI transition
  /// stealing the main thread) — unlike "failed"/"closed", it is not proof
  /// the stream actually ended. Wait this long for a reconnect before
  /// tearing the player down.
  static const _disconnectGracePeriod = Duration(seconds: 6);

  /// Whether this player has been disposed (used by cubit to prevent races).
  bool get isDisposed => _isDisposed;

  Future<void> init() async {
    await renderer.initialize();
    StreamLogFile.log(
        '[LS_RENDERER] initialized textureId=${renderer.textureId}');
    renderer.addListener(() {
      StreamLogFile.log(
        '[LS_RENDERER] value changed: width=${renderer.value.width} '
        'height=${renderer.value.height} rotation=${renderer.value.rotation} '
        'renderVideo=${renderer.value.renderVideo} '
        'rendererRenderVideo=${renderer.renderVideo} textureId=${renderer.textureId}',
      );
    });
    try {
      await Helper.ensureAudioSession();
    } catch (_) {}
    if (Platform.isIOS) {
      // Viewer-only: no local mic track, so ensureAudioSession() never
      // switches the session out of the default ambient/soloAmbient
      // category (setSpeakerphoneOn() is also a no-op unless the category
      // is already playAndRecord). Ambient categories are silenced by the
      // hardware mute switch — video plays, audio doesn't. `.remoteOnly`
      // sets category to `.playback`, which ignores the mute switch.
      try {
        await Helper.setAppleAudioIOMode(AppleAudioIOMode.remoteOnly);
      } catch (_) {}
    } else {
      await Helper.setSpeakerphoneOn(true);
    }
  }

  Future<void> play() async {
    if (_isPlaying || _isDisposed) return;
    _isPlaying = true;

    try {
      StreamLogFile.log('[LS_AUDIO_VIEWER] Starting...');

      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      });

      if (_isDisposed) return;

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        if (_isDisposed) return;
        StreamLogFile.log('[LS_AUDIO_VIEWER] Peer Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _triggerStreamEnded();
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          _handleTransientDisconnect();
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _cancelDisconnectGrace();
        }
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        if (_isDisposed) return;
        StreamLogFile.log('[LS_AUDIO_VIEWER] ICE Connection state: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
            state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
          _triggerStreamEnded();
        } else if (state ==
            RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          _handleTransientDisconnect();
        } else if (state ==
                RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          _cancelDisconnectGrace();
        }
      };

      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      if (_isDisposed) return;

      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      if (_isDisposed) return;

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (_isDisposed) return;
        if (event.streams.isEmpty) {
          StreamLogFile.log(
              '[LS_AUDIO_VIEWER] ${event.track.kind} track received without stream');
          return;
        }

        final eventStream = event.streams.first;
        final audioTracks = eventStream.getAudioTracks();
        final videoTracks = eventStream.getVideoTracks();
        for (final track in audioTracks) {
          track.enabled = true;
          if (!_audioTracks.any((t) => t.id == track.id)) {
            _audioTracks.add(track);
          }
        }

        StreamLogFile.log(
          '[LS_AUDIO_VIEWER] onTrack kind=${event.track.kind} '
          'streamAudio=${audioTracks.length} streamVideo=${videoTracks.length} '
          'trackId=${event.track.id} enabled=${event.track.enabled}',
        );

        // SRS delivers audio and video in two SEPARATE single-track streams
        // (two onTrack events). The renderer only needs the video stream —
        // attaching the audio-only one here used to blank the texture.
        // Audio playout does not require a renderer attachment: received
        // audio tracks play through the native audio device module, and
        // mute/unmute goes through _audioTracks (setAudioEnabled).
        if (event.track.kind == 'video') {
          renderer.srcObject = eventStream;
          unawaited(renderer.setVolume(1.0));
          StreamLogFile.log('[LS_AUDIO_VIEWER] Video track received!');
          event.track.onEnded = () {
            StreamLogFile.log('[LS_AUDIO_VIEWER] Video track ended');
            _triggerStreamEnded();
          };
          return;
        }

        if (event.track.kind == 'audio') {
          StreamLogFile.log(
              '[LS_AUDIO_VIEWER] Audio track received! count=${audioTracks.length}');
          unawaited(Helper.setSpeakerphoneOnButPreferBluetooth());
        }
      };

      final RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      if (_isDisposed) return;

      await _peerConnection!.setLocalDescription(offer);

      if (_isDisposed) return;

      final completer = Completer<void>();
      _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
          if (!completer.isCompleted) completer.complete();
        }
      };

      Timer(const Duration(milliseconds: 500), () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;

      if (_isDisposed) return;

      final fullOffer = await _peerConnection!.getLocalDescription();
      if (fullOffer == null) throw Exception('SDP creation failed');
      StreamLogFile.log(
        '[LS_AUDIO_VIEWER] Local offer has audio=${(fullOffer.sdp ?? '').contains('m=audio')} '
        'video=${(fullOffer.sdp ?? '').contains('m=video')}',
      );

      final RTCSessionDescription answer = await _sendOfferToPlay(fullOffer);
      StreamLogFile.log(
        '[LS_AUDIO_VIEWER] Remote answer has audio=${(answer.sdp ?? '').contains('m=audio')} '
        'video=${(answer.sdp ?? '').contains('m=video')}',
      );

      if (_isDisposed) return;

      await _peerConnection!.setRemoteDescription(answer);

      StreamLogFile.log('[LS_AUDIO_VIEWER] Connection established!');
      _startAudioStatsLog();
    } catch (e) {
      if (_isDisposed) {
        return;
      }
      _isPlaying = false;
      StreamLogFile.log('[LS_AUDIO_VIEWER] Error: $e', isWarning: true);
      rethrow;
    }
  }

  void _startAudioStatsLog() {
    _audioStatsTimer?.cancel();
    _audioStatsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isDisposed) return;
      final pc = _peerConnection;
      if (pc == null) return;

      try {
        final reports = await pc.getStats();
        for (final report in reports) {
          final type = report.type.toLowerCase();
          if (!type.contains('inbound')) continue;

          final mediaType =
              (report.values['mediaType'] ?? report.values['kind'] ?? '')
                  .toString()
                  .toLowerCase();

          if (mediaType == 'video') {
            final framesReceived = report.values['framesReceived'];
            final framesDecoded = report.values['framesDecoded'];
            final framesDropped = report.values['framesDropped'];
            final frameWidth = report.values['frameWidth'];
            final frameHeight = report.values['frameHeight'];
            final codecId = report.values['codecId'];
            final packetsLost = report.values['packetsLost'];
            final packets = report.values['packetsReceived'];

            debugPrint(
              '[LS_VIDEO_VIEWER_STATS] inbound-video packets=$packets lost=$packetsLost '
              'framesReceived=$framesReceived framesDecoded=$framesDecoded framesDropped=$framesDropped '
              'size=${frameWidth}x$frameHeight codecId=$codecId id=${report.id}',
            );
            continue;
          }

          if (mediaType != 'audio') continue;

          final packets = report.values['packetsReceived'];
          final bytes = report.values['bytesReceived'];
          final jitter = report.values['jitter'];
          final level = report.values['audioLevel'];

          StreamLogFile.log(
            '[LS_AUDIO_VIEWER_STATS] inbound-audio packets=$packets bytes=$bytes '
            'jitter=$jitter level=$level id=${report.id}',
          );
        }
      } catch (e) {
        StreamLogFile.log('[LS_AUDIO_VIEWER_STATS] getStats error: $e', isWarning: true);
      }
    });
  }

  void _triggerStreamEnded() {
    if (_isDisposed) return;
    _cancelDisconnectGrace();
    StreamLogFile.log('[LS_AUDIO_VIEWER] Triggering onStreamEnded...');
    onStreamEnded?.call();
    unawaited(dispose());
  }

  /// "Disconnected" means ICE lost its path but hasn't given up — give it
  /// a chance to recover before treating the stream as ended. A recovery
  /// (state flips back to connected/completed) cancels this via
  /// [_cancelDisconnectGrace].
  void _handleTransientDisconnect() {
    if (_disconnectGraceTimer != null) return;
    StreamLogFile.log(
      '[LS_AUDIO_VIEWER] Disconnected — waiting ${_disconnectGracePeriod.inSeconds}s for recovery before ending',
    );
    _disconnectGraceTimer = Timer(_disconnectGracePeriod, () {
      _disconnectGraceTimer = null;
      if (_isDisposed) return;
      StreamLogFile.log(
        '[LS_AUDIO_VIEWER] Disconnected — no recovery within grace period, ending',
        isWarning: true,
      );
      _triggerStreamEnded();
    });
  }

  void _cancelDisconnectGrace() {
    if (_disconnectGraceTimer == null) return;
    StreamLogFile.log(
        '[LS_AUDIO_VIEWER] Connection recovered — cancelling disconnect grace timer');
    _disconnectGraceTimer?.cancel();
    _disconnectGraceTimer = null;
  }

  /// Send SDP offer to SRS server using its standard play API format.
  Future<RTCSessionDescription> _sendOfferToPlay(
      RTCSessionDescription offer) async {
    final url = Uri.parse(playApiUrl);

    String originalSdp = offer.sdp ?? '';

    if (!originalSdp.contains('H264')) {
      List<String> lines = originalSdp.split('\r\n');
      if (lines.length < 2) lines = originalSdp.split('\n');
      List<String> newLines = [];
      bool videoSectionFound = false;
      for (var line in lines) {
        if (line.startsWith('m=video')) {
          videoSectionFound = true;
          newLines.add('$line 126');
          continue;
        }
        newLines.add(line);
        if (videoSectionFound) {
          newLines.add('a=rtpmap:126 H264/90000');
          newLines.add(
              'a=fmtp:126 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f');
          videoSectionFound = false;
        }
      }
      originalSdp = newLines.join('\r\n');
    }

    List<String> lines = originalSdp.split('\n');
    List<String> filteredLines = [];
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.contains('tcp') && trimmed.startsWith('a=candidate:')) {
        continue;
      }
      if (trimmed.contains('::') && trimmed.startsWith('a=candidate:')) {
        continue;
      }
      if (trimmed.contains('extmap-allow-mixed')) {
        continue;
      }
      if (trimmed.contains('msid-semantic')) {
        continue;
      }
      if (trimmed.startsWith('a=msid:')) {
        continue;
      }
      filteredLines.add(trimmed);
    }
    String cleanSdp = filteredLines.join('\r\n');

    final body = jsonEncode({
      'api': playApiUrl,
      'streamurl': streamUrl,
      'sdp': cleanSdp,
    });

    StreamLogFile.log('[LS_AUDIO_VIEWER] POST $url');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    StreamLogFile.log(
        '[LS_AUDIO_VIEWER] Response ${response.statusCode}: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      StreamLogFile.log(
          '[LS_AUDIO_VIEWER] Play response code=${data['code']} keys=${data.keys.toList()}');
      if (data['code'] != 0) {
        throw Exception('SRS play error: ${data['code']}');
      }
      final sdpAnswer = data['sdp'];
      StreamLogFile.log(
          '[LS_AUDIO_VIEWER] Play answer length=${sdpAnswer?.toString().length ?? 0}');
      return RTCSessionDescription(sdpAnswer, 'answer');
    } else {
      throw Exception('Play failed: ${response.statusCode}');
    }
  }

  /// Immediately mute all audio and flag as disposed so async play() stops.
  /// This is safe to call synchronously and prevents audio leaking.
  void stopImmediately() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isPlaying = false;

    // Disable audio tracks first (instant mute, no async needed)
    try {
      setAudioEnabled(false);
    } catch (_) {}
  }

  /// Full async cleanup. Call stopImmediately() first for instant mute.
  Future<void> dispose() async {
    // stopImmediately() may have already set _isDisposed
    if (!_isDisposed) {
      stopImmediately();
    }

    try {
      _audioStatsTimer?.cancel();
      _audioStatsTimer = null;
      _disconnectGraceTimer?.cancel();
      _disconnectGraceTimer = null;
    } catch (_) {}

    try {
      // Stop all tracks. Audio tracks live outside the renderer's stream
      // (see _audioTracks doc), so stop them explicitly too.
      for (final track in _audioTracks) {
        try {
          track.stop();
        } catch (_) {}
      }
      renderer.srcObject?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
      renderer.srcObject = null;
      _audioTracks.clear();
    } catch (_) {}

    try {
      await Helper.setSpeakerphoneOn(false);
    } catch (_) {}

    try {
      await _peerConnection?.close();
      _peerConnection = null;
    } catch (e) {
      StreamLogFile.log('[LS_AUDIO_VIEWER] Error closing peer connection: $e',
          isWarning: true);
    }

    try {
      await renderer.dispose();
    } catch (e) {
      StreamLogFile.log('[LS_AUDIO_VIEWER] Error disposing renderer: $e',
          isWarning: true);
    }
  }
}
