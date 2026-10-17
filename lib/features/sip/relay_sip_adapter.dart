import 'dart:developer' as developer;

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:relay/features/call/models/call_lifecycle.dart';
import 'package:relay/features/call/models/call_session.dart';
import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:sip_ua/sip_ua.dart';

class RelaySipAdapter implements SipUaHelperListener {
  RelaySipAdapter({SIPUAHelper? helper}) : _helper = helper ?? SIPUAHelper() {
    _helper.addSipUaHelperListener(this);
  }

  final SIPUAHelper _helper;

  void Function(SipRegistrationStatus status, {String? errorMessage})? onStatusChanged;

  void Function(CallSession session)? onCallSessionChanged;
  void Function(MediaStream remoteStream)? onRemoteStreamAdded;

  Call? _activeCall;
  DateTime? _answeredAt;

  Call? get activeCall => _activeCall;
  bool get isRegistered => _helper.registered;

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
    return _helper.call(targetUri, voiceOnly: true, mediaStream: mediaStream);
  }

  Future<void> answerCall({MediaStream? mediaStream}) async {
    if (_activeCall == null) {
      _log('Cannot answer: no active incoming call');
      return;
    }
    _log('Answering incoming call ${_activeCall!.id}');
    final options = _helper.buildCallOptions(true);
    _activeCall!.answer(options, mediaStream: mediaStream);
  }

  Future<void> hangupCall() async {
    if (_activeCall != null) {
      _log('Hanging up call ${_activeCall!.id}');
      try {
        _activeCall!.hangup();
      } catch (e) {
        _log('Safe error on hangup: $e');
      }
      _activeCall = null;
    }
  }

  void mute({bool audio = true}) {
    if (_activeCall != null) {
      _log('Call mute audio set to: $audio');
      if (audio) {
        _activeCall!.mute(true, false);
      } else {
        _activeCall!.unmute(true, false);
      }
    }
  }

  void dispose() {
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

    _activeCall = call;

    final direction = call.direction == Direction.incoming ? CallDirection.incoming : CallDirection.outgoing;

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
        );
      case CallStateEnum.STREAM:
        _log('Call media stream received: originator=${state.originator}');
        if (state.stream != null && state.originator == Originator.remote) {
          onRemoteStreamAdded?.call(state.stream!);
          for (final track in state.stream!.getAudioTracks()) {
            track.enabled = true;
          }
        }
      case CallStateEnum.ENDED:
        _log('Call ended: ${state.cause}');
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
        );
      case CallStateEnum.FAILED:
        _log('Call failed: ${state.cause}');
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

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  String _formatCallError(dynamic cause) {
    if (cause == null) return 'Call failed';
    try {
      final statusCode = cause.status_code;
      if (statusCode == 486) return 'User is busy';
      if (statusCode == 480 || statusCode == 404) {
        return 'Destination unavailable';
      }
      if (statusCode == 603 || statusCode == 403) return 'Call declined';
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

  void _log(String message) {
    developer.log('[RelaySIP] $message', name: 'relay.sip');
  }
}
