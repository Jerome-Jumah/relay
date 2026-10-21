import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:relay/features/call/models/call_lifecycle.dart';
import 'package:relay/features/call/models/call_session.dart';
import 'package:relay/features/call/models/requested_call_mode.dart';
import 'package:relay/features/rtc_lab/models/rtc_lab_event.dart';
import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:sip_ua/sip_ua.dart';

class RelaySipAdapter implements SipUaHelperListener {
  RelaySipAdapter({SIPUAHelper? helper}) : _helper = helper ?? SIPUAHelper() {
    _helper.addSipUaHelperListener(this);
  }

  final SIPUAHelper _helper;

  void Function(SipRegistrationStatus status, {String? errorMessage})? onStatusChanged;

  void Function(CallSession session, {bool hasVideo, bool videoCapability, RequestedCallMode requestedCallMode})?
  onCallSessionChanged;
  void Function(MediaStream remoteStream)? onRemoteStreamAdded;
  void Function({required bool hasVideo})? onRemoteReinviteAccepted;
  void Function(RtcLabEventCategory category, String title, {String? detail})? onDiagnosticEvent;

  Call? _activeCall;
  DateTime? _answeredAt;
  Timer? _videoDiagnosticsTimer;
  int? _hookedPeerConnectionHash;
  bool _selectedCandidatePairLogged = false;
  String? _lastRemoteStreamTracksSignature;

  Call? get activeCall => _activeCall;
  RTCPeerConnection? get peerConnection => _activeCall?.peerConnection;
  bool get isRegistered => _helper.registered;

  static List<Map<String, String>> buildIceServers() {
    final stunUrl = dotenv.env['STUN_URL']?.trim().isNotEmpty == true
        ? dotenv.env['STUN_URL']!.trim()
        : 'stun:turn.code4flare.com:3478';

    final turnBase = dotenv.env['TURN_URL']?.trim().isNotEmpty == true
        ? dotenv.env['TURN_URL']!.trim()
        : 'turn:turn.code4flare.com:3478';

    final turnUsername = dotenv.env['TURN_USERNAME']?.trim() ?? '';
    final turnPassword = dotenv.env['TURN_PASSWORD']?.trim() ?? '';

    final udpTurnUrl = turnBase.contains('?') ? turnBase : '$turnBase?transport=udp';
    final tcpTurnUrl = turnBase.contains('?') ? turnBase : '$turnBase?transport=tcp';

    return [
      {'urls': stunUrl},
      if (turnUsername.isNotEmpty && turnPassword.isNotEmpty) ...[
        {'urls': udpTurnUrl, 'username': turnUsername, 'credential': turnPassword},
        {'urls': tcpTurnUrl, 'username': turnUsername, 'credential': turnPassword},
      ],
    ];
  }

  Future<void> register(SipAccountConfig config) async {
    _log('Initiating registration for URI: ${config.sipUri}');
    _log('Signaling WebSocket URL: ${config.webSocketUrl}');
    _log('Authorization user: ${config.authorizationUser}');

    onStatusChanged?.call(SipRegistrationStatus.connecting);

    final uaSettings = UaSettings();
    uaSettings.transportType = TransportType.WS;
    uaSettings.webSocketUrl = config.webSocketUrl.trim();
    uaSettings.uri = config.sipUri;
    uaSettings.authorizationUser = config.authorizationUser;
    uaSettings.password = config.password;
    uaSettings.displayName = config.extension.trim();
    uaSettings.register = true;

    final iceServers = buildIceServers();
    uaSettings.iceServers = iceServers;
    final hasTurn = dotenv.env['TURN_USERNAME']?.trim().isNotEmpty == true;
    _log(
      'Configured ${iceServers.length} ICE server(s): ${iceServers.map((s) => s['urls']).join(', ')} (TURN credentials: ${hasTurn ? 'present' : 'none'})',
    );

    await _helper.start(uaSettings);
  }

  Future<void> unregister() async {
    _log('Unregistering SIP user agent');
    try {
      if (_helper.registered) {
        await _helper.unregister();
      }
      _helper.stop();
    } catch (e) {
      _log('Safe error during unregister: $e');
    }
    onStatusChanged?.call(SipRegistrationStatus.disconnected);
  }

  Future<bool> makeAudioCall(String targetUri, {MediaStream? mediaStream}) async {
    _log('Initiating audio call to $targetUri');
    if (!_helper.connected) {
      _log('Cannot make call: SIP UA not connected');
      return false;
    }
    _answeredAt = null;
    _resetDiagnostics();
    final iceServers = buildIceServers();
    return _helper.call(
      targetUri,
      voiceOnly: true,
      mediaStream: mediaStream,
      headers: <String>['X-Relay-Call-Mode: audio'],
      customOptions: <String, dynamic>{
        'videoReady': true,
        'pcConfig': <String, dynamic>{'iceServers': iceServers, 'videoReady': true},
        'rtcOfferConstraints': <String, dynamic>{
          'mandatory': <String, dynamic>{'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
          'optional': <dynamic>[],
        },
        'rtcAnswerConstraints': <String, dynamic>{
          'mandatory': <String, dynamic>{'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
          'optional': <dynamic>[],
        },
      },
    );
  }

  Future<bool> makeVideoCall(String targetUri, {MediaStream? mediaStream}) async {
    _log('Initiating video call to $targetUri');
    if (!_helper.connected) {
      _log('Cannot make call: SIP UA not connected');
      return false;
    }
    _answeredAt = null;
    _resetDiagnostics();
    final iceServers = buildIceServers();
    return _helper.call(
      targetUri,
      voiceOnly: false,
      mediaStream: mediaStream,
      headers: <String>['X-Relay-Call-Mode: video'],
      customOptions: <String, dynamic>{
        'pcConfig': <String, dynamic>{'iceServers': iceServers},
      },
    );
  }

  Future<void> answerCall({MediaStream? mediaStream}) async {
    if (_activeCall == null) {
      _log('Cannot answer: no active incoming call');
      return;
    }
    _log('Answering incoming audio call ${_activeCall!.id}');
    final options = _helper.buildCallOptions(true);
    final pcConfig = options['pcConfig'] as Map<String, dynamic>? ?? <String, dynamic>{};
    pcConfig['iceServers'] = buildIceServers();
    pcConfig['videoReady'] = true;
    options['pcConfig'] = pcConfig;
    options['videoReady'] = true;
    options['rtcAnswerConstraints'] = <String, dynamic>{
      'mandatory': <String, dynamic>{'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
      'optional': <dynamic>[],
    };
    _activeCall!.answer(options, mediaStream: mediaStream);
  }

  Future<void> answerVideoCall({MediaStream? mediaStream}) async {
    if (_activeCall == null) {
      _log('Cannot answer: no active incoming call');
      return;
    }
    _log('Answering incoming video call ${_activeCall!.id}');
    final options = _helper.buildCallOptions(false);
    final pcConfig = options['pcConfig'] as Map<String, dynamic>? ?? <String, dynamic>{};
    pcConfig['iceServers'] = buildIceServers();
    options['pcConfig'] = pcConfig;
    _activeCall!.answer(options, mediaStream: mediaStream);
  }

  Future<void> hangupCall() async {
    _stopVideoDiagnostics();
    if (_activeCall != null) {
      final callToHangup = _activeCall!;
      _log('Hanging up call ${callToHangup.id}');
      try {
        callToHangup.hangup();
      } catch (e) {
        _log('Safe error on hangup: $e');
        _resetDiagnostics();
        _activeCall = null;
      }
    }
  }

  void mute({bool audio = false, bool video = false}) {
    if (_activeCall != null) {
      _log('Call mute set to: audio=$audio, video=$video');
      _activeCall!.mute(audio, video);
    }
  }

  void unmute({bool audio = false, bool video = false}) {
    if (_activeCall != null) {
      _log('Call unmute set to: audio=$audio, video=$video');
      _activeCall!.unmute(audio, video);
    }
  }

  void dispose() {
    _resetDiagnostics();
    _helper.removeSipUaHelperListener(this);
    try {
      if (_activeCall != null) {
        _activeCall!.hangup();
        _activeCall = null;
      }
      _helper.stop();
    } catch (_) {}
  }

  @override
  void transportStateChanged(TransportState state) {
    _log('Transport state changed: ${state.state}');
    switch (state.state) {
      case TransportStateEnum.CONNECTING:
        onStatusChanged?.call(SipRegistrationStatus.connecting);
      case TransportStateEnum.CONNECTED:
        _log('Transport socket connected');
      case TransportStateEnum.DISCONNECTED:
        _log('Transport socket disconnected');
        final error = state.cause?.cause;
        onStatusChanged?.call(SipRegistrationStatus.disconnected, errorMessage: error);
      case TransportStateEnum.NONE:
        break;
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    _log('Registration state changed: ${state.state}');
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        onStatusChanged?.call(SipRegistrationStatus.registered);
      case RegistrationStateEnum.REGISTRATION_FAILED:
        final safeReason = _formatSafeError(state.cause);
        _log('Registration failed: $safeReason');
        onStatusChanged?.call(SipRegistrationStatus.failed, errorMessage: safeReason);
      case RegistrationStateEnum.UNREGISTERED:
        onStatusChanged?.call(SipRegistrationStatus.disconnected);
      case RegistrationStateEnum.NONE:
      case null:
        onStatusChanged?.call(SipRegistrationStatus.idle);
    }
  }

  @override
  void callStateChanged(Call call, CallState state) {
    _log('Call state changed: id=${call.id}, state=${state.state}');

    if (_activeCall != null && _activeCall!.id != call.id) {
      if (state.state != CallStateEnum.ENDED && state.state != CallStateEnum.FAILED) {
        _log('Rejecting simultaneous call: ${call.id}');
        try {
          call.hangup({'status_code': 486, 'reason_phrase': 'Busy Here'});
        } catch (_) {}
      }
      return;
    }

    final isTerminal = state.state == CallStateEnum.ENDED || state.state == CallStateEnum.FAILED;

    if (!isTerminal) {
      if (_activeCall == null || _activeCall!.id != call.id) {
        _resetDiagnostics();
      }
      _activeCall = call;
      _attachDiagnostics(call);
    }

    final direction = call.direction == Direction.incoming ? CallDirection.incoming : CallDirection.outgoing;
    final requestedMode = _parseRequestedCallMode(call);
    final hasVideo = direction == CallDirection.outgoing
        ? !call.voiceOnly
        : (requestedMode == RequestedCallMode.video && _checkCallHasVideo(call));
    final videoCapability = _checkCallHasVideoCapability(call);

    final peer = call.remote_identity?.trim().isNotEmpty == true
        ? call.remote_identity!.trim()
        : (call.remote_display_name?.trim().isNotEmpty == true ? call.remote_display_name!.trim() : 'Unknown');

    switch (state.state) {
      case CallStateEnum.CALL_INITIATION:
        final lifecycle = direction == CallDirection.incoming ? CallLifecycle.incoming : CallLifecycle.outgoing;
        onCallSessionChanged?.call(
          CallSession(
            id: call.id ?? '',
            peer: peer,
            direction: direction,
            lifecycle: lifecycle,
            initiatedAt: DateTime.now(),
          ),
          hasVideo: hasVideo,
          videoCapability: videoCapability,
          requestedCallMode: requestedMode,
        );
      case CallStateEnum.CONNECTING:
        onCallSessionChanged?.call(
          CallSession(
            id: call.id ?? '',
            peer: peer,
            direction: direction,
            lifecycle: CallLifecycle.connecting,
            initiatedAt: DateTime.now(),
          ),
          hasVideo: hasVideo,
          videoCapability: videoCapability,
          requestedCallMode: requestedMode,
        );
      case CallStateEnum.PROGRESS:
        _log('Call progress (ringing on remote)');
        onCallSessionChanged?.call(
          CallSession(
            id: call.id ?? '',
            peer: peer,
            direction: direction,
            lifecycle: CallLifecycle.ringing,
            initiatedAt: DateTime.now(),
          ),
          hasVideo: hasVideo,
          videoCapability: videoCapability,
          requestedCallMode: requestedMode,
        );
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        _log('Call established (200 OK / ACK)');
        _answeredAt ??= DateTime.now();
        onCallSessionChanged?.call(
          CallSession(
            id: call.id ?? '',
            peer: peer,
            direction: direction,
            lifecycle: CallLifecycle.active,
            answeredAt: _answeredAt,
          ),
          hasVideo: hasVideo,
          videoCapability: videoCapability,
          requestedCallMode: requestedMode,
        );
      case CallStateEnum.STREAM:
        final stream = state.stream;
        final streamId = stream?.id ?? 'unknown';
        final audioCount = stream?.getAudioTracks().length ?? 0;
        final videoCount = stream?.getVideoTracks().length ?? 0;
        final streamSignature = '$streamId:orig=${state.originator}:a=$audioCount:v=$videoCount';

        final isDuplicateStreamEvent = _lastRemoteStreamTracksSignature == streamSignature;
        if (!isDuplicateStreamEvent) {
          _lastRemoteStreamTracksSignature = streamSignature;
          _log('Call media stream received: originator=${state.originator}');
        }

        if (stream != null && state.originator == Originator.remote) {
          final hasVideoTrack = videoCount > 0;
          final hasAudioTrack = audioCount > 0;
          if (!isDuplicateStreamEvent) {
            _log(
              '[RTC Diagnostics] Remote video track ${hasVideoTrack ? 'present' : 'absent'} (audio=${hasAudioTrack ? 'present' : 'absent'})',
            );
          }
          onRemoteStreamAdded?.call(stream);
          for (final track in stream.getAudioTracks()) {
            track.enabled = true;
          }
        }
      case CallStateEnum.ENDED:
        _log('Call ended: ${state.cause}');
        _resetDiagnostics();
        final endedAt = DateTime.now();
        final answered = _answeredAt;
        _answeredAt = null;
        _activeCall = null;
        onCallSessionChanged?.call(
          CallSession(
            id: call.id ?? '',
            peer: peer,
            direction: direction,
            lifecycle: CallLifecycle.ended,
            answeredAt: answered,
            endedAt: endedAt,
          ),
          hasVideo: hasVideo,
          videoCapability: videoCapability,
          requestedCallMode: requestedMode,
        );
      case CallStateEnum.FAILED:
        _log('Call failed: ${state.cause}');
        _resetDiagnostics();
        final endedAt = DateTime.now();
        final answered = _answeredAt;
        _answeredAt = null;
        _activeCall = null;
        final failureReason = _formatCallError(state.cause);
        onCallSessionChanged?.call(
          CallSession(
            id: call.id ?? '',
            peer: peer,
            direction: direction,
            lifecycle: CallLifecycle.failed,
            answeredAt: answered,
            endedAt: endedAt,
            failureReason: failureReason,
          ),
          hasVideo: hasVideo,
          videoCapability: videoCapability,
          requestedCallMode: requestedMode,
        );
      case CallStateEnum.MUTED:
      case CallStateEnum.UNMUTED:
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
      case CallStateEnum.REFER:
      case CallStateEnum.NONE:
        break;
    }
  }

  static bool isRemoteVideoActiveInParsedSdp(Map<String, dynamic>? parsedSdp) {
    if (parsedSdp == null) return false;
    final mediaList = parsedSdp['media'];
    if (mediaList is List) {
      final sessionDir = parsedSdp['direction']?.toString().toLowerCase().trim();
      for (final m in mediaList) {
        if (m is Map && m['type'] == 'video') {
          final port = m['port'];
          if (port == 0 || port == '0') return false;
          final mediaDir = m['direction']?.toString().toLowerCase().trim();
          final effectiveDir = mediaDir ?? sessionDir ?? 'sendrecv';
          if (effectiveDir == 'recvonly' || effectiveDir == 'inactive') {
            return false;
          }
          if (effectiveDir == 'sendrecv' || effectiveDir == 'sendonly') {
            return true;
          }
          return false;
        }
      }
    }
    return false;
  }

  static bool isRemoteVideoActiveInSdp(String? sdpString, {Map<String, dynamic>? parsedSdp}) {
    if (sdpString == null || sdpString.isEmpty) return false;
    if (!sdpString.contains('m=video')) return false;
    if (RegExp(r'm=video\s+0\b').hasMatch(sdpString)) return false;

    // 1. Check structured SDP if available
    if (parsedSdp != null) {
      return isRemoteVideoActiveInParsedSdp(parsedSdp);
    }

    // 2. Robust regex inspection of raw SDP lines
    final mVideoMatch = RegExp(r'(?:^|\r?\n)m=video\s+(\d+)').firstMatch(sdpString);
    if (mVideoMatch == null) return false;
    final portStr = mVideoMatch.group(1);
    if (portStr == '0') return false;

    final videoStartIndex = mVideoMatch.start;
    final nextMLineMatch = RegExp(r'\r?\nm=[a-z]+').firstMatch(sdpString.substring(videoStartIndex + 1));
    final videoBlock = nextMLineMatch != null
        ? sdpString.substring(videoStartIndex, videoStartIndex + 1 + nextMLineMatch.start)
        : sdpString.substring(videoStartIndex);

    // Media-level direction takes precedence
    if (RegExp(r'(?:^|\r?\n)a=(recvonly|inactive)\b').hasMatch(videoBlock)) {
      return false;
    }
    if (RegExp(r'(?:^|\r?\n)a=(sendrecv|sendonly)\b').hasMatch(videoBlock)) {
      return true;
    }

    // Session-level direction fallback (before first m= line)
    final firstMLineIndex = sdpString.indexOf(RegExp(r'\r?\nm='));
    final sessionBlock = firstMLineIndex != -1 ? sdpString.substring(0, firstMLineIndex) : '';
    if (RegExp(r'(?:^|\r?\n)a=(recvonly|inactive)\b').hasMatch(sessionBlock)) {
      return false;
    }
    if (RegExp(r'(?:^|\r?\n)a=(sendrecv|sendonly)\b').hasMatch(sessionBlock)) {
      return true;
    }

    // If direction is completely omitted, RFC 4566 default is sendrecv
    return true;
  }

  static bool hasVideoCapabilityInSdp(String? sdpString) {
    if (sdpString == null || sdpString.isEmpty) return false;
    if (!sdpString.contains('m=video')) return false;
    if (RegExp(r'm=video\s+0\b').hasMatch(sdpString)) return false;
    return true;
  }

  RequestedCallMode _parseRequestedCallMode(Call call) {
    if (call.direction == Direction.outgoing) {
      return call.voiceOnly ? RequestedCallMode.audio : RequestedCallMode.video;
    }

    final req = call.session.request;
    if (req != null) {
      try {
        final modeHeader = req.getHeader('X-Relay-Call-Mode')?.toString().toLowerCase().trim();
        if (modeHeader == 'video') {
          return RequestedCallMode.video;
        } else if (modeHeader == 'audio') {
          return RequestedCallMode.audio;
        }

        final rawStr = req.toString();
        final match = RegExp(r'x-relay-call-mode:\s*([a-zA-Z]+)', caseSensitive: false).firstMatch(rawStr);
        if (match != null) {
          final mode = match.group(1)?.toLowerCase().trim();
          if (mode == 'video') return RequestedCallMode.video;
          if (mode == 'audio') return RequestedCallMode.audio;
        }
      } catch (_) {}
    }

    // Fallback if header is omitted (e.g. 3rd-party client or legacy):
    final hasActiveRemoteVideo = _checkCallHasVideo(call);
    return hasActiveRemoteVideo ? RequestedCallMode.video : RequestedCallMode.audio;
  }

  bool _checkCallHasVideo(Call call) {
    // If local initiated a video call, local intent was active video
    if (!call.voiceOnly && call.direction == Direction.outgoing) {
      return true;
    }

    final data = call.session.data;
    if (data is Map && data?['video'] == true && data?['videoReady'] != true) {
      return true;
    }

    final req = call.session.request;
    if (req != null) {
      try {
        final body = req.body?.toString();
        if (body != null && body.isNotEmpty) {
          Map<String, dynamic>? parsed;
          try {
            parsed = (req as dynamic).parseSDP();
          } catch (_) {}
          return isRemoteVideoActiveInSdp(body, parsedSdp: parsed);
        }
      } catch (_) {}
    }
    return false;
  }

  bool _checkCallHasVideoCapability(Call call) {
    final data = call.session.data;
    if (data is Map && data?['videoReady'] == true) {
      return true;
    }
    final req = call.session.request;
    if (req != null) {
      try {
        final body = req.body?.toString();
        if (body != null && body.isNotEmpty) {
          return hasVideoCapabilityInSdp(body);
        }
      } catch (_) {}
    }
    return false;
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  Future<bool> renegotiate({bool voiceOnly = false}) async {
    final call = _activeCall;
    if (call == null) {
      _log('Cannot renegotiate: no active call');
      return false;
    }
    _log('[RTC Diagnostics] SIP renegotiation started (voiceOnly=$voiceOnly)');

    final completer = Completer<bool>();

    final options = <String, dynamic>{
      'mediaConstraints': <String, dynamic>{'audio': true, 'video': false},
      'rtcOfferConstraints': <String, dynamic>{
        'mandatory': <String, dynamic>{'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
        'optional': <dynamic>[],
      },
      'pcConfig': <String, dynamic>{'iceServers': buildIceServers(), 'videoReady': true},
      'videoReady': true,
    };

    final initiated = call.session.renegotiate(
      options: options,
      done: (response) {
        final status = response?.status_code;
        _log('[RTC Diagnostics] SIP renegotiation response received: status=$status');
        if (!completer.isCompleted) {
          final is2xx = status != null && status >= 200 && status < 300;
          if (!is2xx) {
            completer.complete(false);
            return;
          }
          if (!voiceOnly) {
            final body = response?.body ?? '';
            final hasVideo = body.contains('m=video') && !RegExp(r'm=video 0\b').hasMatch(body);
            if (!hasVideo) {
              _log('[RTC Diagnostics] SIP renegotiation 200 OK did not accept video (answer was audio-only)');
              completer.complete(false);
              return;
            }
          }
          completer.complete(true);
        }
      },
    );

    if (!initiated) {
      _log('[RTC Diagnostics] SIP renegotiation rejected by RTCSession');
      return false;
    }

    try {
      return await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _log('[RTC Diagnostics] SIP renegotiation timed out');
          return false;
        },
      );
    } catch (e) {
      _log('[RTC Diagnostics] SIP renegotiation error: $e');
      return false;
    }
  }

  @override
  void onNewReinvite(ReInvite event) {
    final hasAudio = event.hasAudio ?? false;
    bool hasVideo = false;
    if (event.sdp != null) {
      hasVideo = isRemoteVideoActiveInParsedSdp(event.sdp);
    } else {
      hasVideo = event.hasVideo ?? false;
    }
    _log('[RTC Diagnostics] Incoming re-INVITE received: hasAudio=$hasAudio, hasVideo=$hasVideo');
    try {
      event.accept?.call({});
      _log('[RTC Diagnostics] Incoming re-INVITE accepted');
      onRemoteReinviteAccepted?.call(hasVideo: hasVideo);
    } catch (e) {
      _log('[RTC Diagnostics] Error accepting re-INVITE: $e');
    }
  }

  String _formatCallError(dynamic cause) {
    if (cause == null) return 'Call failed';
    try {
      final statusCode = cause.status_code;
      if (statusCode == 486) return 'User is busy';
      if (statusCode == 480 || statusCode == 404) {
        return 'Destination unavailable';
      }
      if (statusCode == 603 || statusCode == 403) return 'Call declined';
      if (statusCode == 408) return 'RTP timeout: ICE connection failed';
      final causeText = cause.cause?.toString().toUpperCase() ?? '';
      if (causeText.contains('BUSY')) return 'User is busy';
      if (causeText.contains('REJECTED')) return 'Call declined';
      if (causeText.contains('UNAVAILABLE') || causeText.contains('NOT_FOUND')) {
        return 'Destination unavailable';
      }
      if (causeText.contains('USER_DENIED_MEDIA_ACCESS')) {
        return 'Microphone permission denied';
      }
      if (causeText.contains('CANCELED')) return 'Call canceled';
      final reasonPhrase = cause.reason_phrase?.toString();
      if (reasonPhrase != null && reasonPhrase.isNotEmpty) {
        return reasonPhrase;
      }
    } catch (_) {}
    return 'Call failed';
  }

  String _formatSafeError(dynamic cause) {
    if (cause == null) return 'Registration failed';
    try {
      final statusCode = cause.status_code;
      if (statusCode == 401 || statusCode == 403) {
        return 'Authentication failed. Please check extension and password.';
      }
      final reasonPhrase = cause.reason_phrase;
      if (reasonPhrase != null && reasonPhrase.toString().isNotEmpty) {
        return reasonPhrase.toString();
      }
      final causeText = cause.cause;
      if (causeText != null && causeText.toString().isNotEmpty) {
        return causeText.toString();
      }
    } catch (_) {}
    return 'Registration failed';
  }

  final Set<String> _diagnosticsSessions = <String>{};

  void _attachDiagnostics(Call call) {
    final id = call.id ?? '';
    if (id.isNotEmpty && !_diagnosticsSessions.contains(id)) {
      _diagnosticsSessions.add(id);
      _log('[RTC Diagnostics] Call session registered: id=$id');
    }
    _hookPeerConnection(call);
  }

  void _hookPeerConnection(Call call) {
    final pc = call.peerConnection;
    if (pc == null) return;

    final pcHash = identityHashCode(pc);
    if (_hookedPeerConnectionHash == pcHash) {
      return;
    }
    _hookedPeerConnectionHash = pcHash;

    final origIceCandidate = pc.onIceCandidate;
    pc.onIceCandidate = (candidate) {
      final candStr = candidate.candidate ?? '';
      final typMatch = RegExp(r'\btyp\s+(\w+)').firstMatch(candStr);
      final candType = typMatch?.group(1) ?? 'unknown';
      final protoMatch = RegExp(r'\b(udp|tcp)\b', caseSensitive: false).firstMatch(candStr);
      final protocol = protoMatch?.group(1)?.toUpperCase() ?? 'UDP';
      _log('[RTC Diagnostics] Local ICE candidate gathered: typ=$candType protocol=$protocol');
      origIceCandidate?.call(candidate);
    };

    final origIceConnection = pc.onIceConnectionState;
    pc.onIceConnectionState = (state) {
      _log('[RTC Diagnostics] ICE Connection State: ${state.name}');
      onDiagnosticEvent?.call(RtcLabEventCategory.ice, 'ICE State: ${state.name}');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        if (!_selectedCandidatePairLogged) {
          _selectedCandidatePairLogged = true;
          _logSelectedCandidatePair(pc);
        }
        _startVideoDiagnostics(pc);
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _stopVideoDiagnostics();
      }
      origIceConnection?.call(state);
    };

    final origIceGathering = pc.onIceGatheringState;
    pc.onIceGatheringState = (state) {
      _log('[RTC Diagnostics] ICE Gathering State: ${state.name}');
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        _logLocalSdpCandidates(pc);
      }
      origIceGathering?.call(state);
    };

    final origConnectionState = pc.onConnectionState;
    pc.onConnectionState = (state) {
      _log('[RTC Diagnostics] PeerConnection State: ${state.name}');
      onDiagnosticEvent?.call(RtcLabEventCategory.ice, 'PeerConnection: ${state.name}');
      origConnectionState?.call(state);
    };

    _logLocalSdpCandidates(pc);
    pc
        .getTransceivers()
        .then((transceivers) {
          for (final t in transceivers) {
            if (t.sender.track?.kind == 'video' || t.receiver.track?.kind == 'video') {
              t.getDirection().then((dir) {
                final dirStr = typeRtpTransceiverDirectionToString[dir] ?? 'recvonly';
                _log('[RTC Diagnostics] Video-ready transceiver created: direction=$dirStr');
              });
              break;
            }
          }
        })
        .catchError((_) {});
  }

  void _startVideoDiagnostics(RTCPeerConnection pc) {
    if (_videoDiagnosticsTimer != null && _videoDiagnosticsTimer!.isActive) {
      return;
    }
    _videoDiagnosticsTimer?.cancel();
    _videoDiagnosticsTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_activeCall == null) {
        _stopVideoDiagnostics();
        return;
      }
      await _logVideoStats(pc);
    });
  }

  void _stopVideoDiagnostics() {
    _videoDiagnosticsTimer?.cancel();
    _videoDiagnosticsTimer = null;
  }

  void _resetDiagnostics() {
    _stopVideoDiagnostics();
    _hookedPeerConnectionHash = null;
    _selectedCandidatePairLogged = false;
    _lastRemoteStreamTracksSignature = null;
    _diagnosticsSessions.clear();
  }

  Future<void> _logVideoStats(RTCPeerConnection pc) async {
    try {
      final stats = await pc.getStats();
      final codecs = <String, String>{};
      for (final report in stats) {
        if (report.type == 'codec') {
          final mime = report.values['mimeType']?.toString() ?? report.values['codec']?.toString();
          if (mime != null) {
            codecs[report.id] = mime;
          }
        }
      }

      for (final report in stats) {
        final kind = report.values['kind']?.toString() ?? report.values['mediaType']?.toString();
        if (kind == 'video') {
          if (report.type == 'outbound-rtp') {
            final codecId = report.values['codecId']?.toString();
            final codec = codecs[codecId] ?? codecId ?? 'unknown';
            final w = report.values['frameWidth'];
            final h = report.values['frameHeight'];
            final framesSent = report.values['framesSent'];
            final bytesSent = report.values['bytesSent'];
            _log(
              '[RTC Diagnostics] Outbound video: codec=$codec, res=${w}x$h, framesSent=$framesSent, bytesSent=$bytesSent',
            );
          } else if (report.type == 'inbound-rtp') {
            final codecId = report.values['codecId']?.toString();
            final codec = codecs[codecId] ?? codecId ?? 'unknown';
            final w = report.values['frameWidth'];
            final h = report.values['frameHeight'];
            final framesRecv = report.values['framesReceived'];
            final bytesRecv = report.values['bytesReceived'];
            _log(
              '[RTC Diagnostics] Inbound video: codec=$codec, res=${w}x$h, framesRecv=$framesRecv, bytesRecv=$bytesRecv',
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _logLocalSdpCandidates(RTCPeerConnection pc) async {
    try {
      final desc = await pc.getLocalDescription();
      if (desc?.sdp != null) {
        final sdp = desc!.sdp!;
        if (sdp.contains('m=video') && !RegExp(r'm=video 0\b').hasMatch(sdp)) {
          if (_activeCall?.voiceOnly == true) {
            _log('[RTC Diagnostics] Initial audio SDP contains dormant video');
          }
        }
        final matches = RegExp(r'a=candidate:.*\btyp\s+(\w+).*?\b(udp|tcp)\b', caseSensitive: false).allMatches(sdp);
        for (final m in matches) {
          final typ = m.group(1);
          final proto = m.group(2)?.toUpperCase() ?? 'UDP';
          _log('[RTC Diagnostics] Local SDP candidate: typ=$typ protocol=$proto');
        }
      }
    } catch (_) {}
  }

  Future<void> _logSelectedCandidatePair(RTCPeerConnection pc) async {
    try {
      final stats = await pc.getStats();

      // Precedence:
      // A. transport.selectedCandidatePairId
      // B. candidate-pair selected == true
      // C. nominated == true AND state == "succeeded"
      StatsReport? selectedReport;

      // A. Check transport stats
      String? transportPairId;
      for (final r in stats) {
        if (r.type == 'transport') {
          final pid = r.values['selectedCandidatePairId']?.toString();
          if (pid != null && pid.isNotEmpty) {
            transportPairId = pid;
            break;
          }
        }
      }

      if (transportPairId != null) {
        for (final r in stats) {
          if (r.type == 'candidate-pair' && r.id == transportPairId) {
            selectedReport = r;
            break;
          }
        }
      }

      // B. candidate-pair selected == true
      if (selectedReport == null) {
        for (final r in stats) {
          if (r.type == 'candidate-pair') {
            final isSelected = r.values['selected'] == true || r.values['selected']?.toString().toLowerCase() == 'true';
            if (isSelected) {
              selectedReport = r;
              break;
            }
          }
        }
      }

      // C. nominated == true AND state == "succeeded"
      if (selectedReport == null) {
        for (final r in stats) {
          if (r.type == 'candidate-pair') {
            final isNominated =
                r.values['nominated'] == true || r.values['nominated']?.toString().toLowerCase() == 'true';
            final stateVal = r.values['state']?.toString().toLowerCase();
            if (isNominated && stateVal == 'succeeded') {
              selectedReport = r;
              break;
            }
          }
        }
      }

      if (selectedReport == null) {
        _log('[RTC Diagnostics] No active selected candidate pair resolved yet');
        return;
      }

      final localCandId = selectedReport.values['localCandidateId'];
      final remoteCandId = selectedReport.values['remoteCandidateId'];

      String localType = 'unknown';
      String remoteType = 'unknown';
      final protocol = selectedReport.values['protocol']?.toString() ?? 'UDP';

      for (final r in stats) {
        if (r.id == localCandId) {
          localType = r.values['candidateType']?.toString() ?? 'unknown';
        }
        if (r.id == remoteCandId) {
          remoteType = r.values['candidateType']?.toString() ?? 'unknown';
        }
      }

      _log('[RTC Diagnostics] Selected candidate pair: local=$localType, remote=$remoteType ($protocol)');
      onDiagnosticEvent?.call(
        RtcLabEventCategory.ice,
        'Selected Path: $localType → $remoteType ($protocol)',
        detail: 'Local: $localType ($protocol), Remote: $remoteType',
      );
    } catch (e) {
      _log('[RTC Diagnostics] Candidate pair lookup: $e');
    }
  }

  void _log(String message) {
    developer.log('[RelaySIP] $message', name: 'relay.sip');
  }
}
