import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:relay/features/call/models/call_lifecycle.dart';
import 'package:relay/features/call/models/call_session.dart';
import 'package:relay/features/call/models/call_state_data.dart';
import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:relay/features/sip/sip_controller.dart';
import 'package:relay/shared/permissions/relay_permissions.dart';

class CallController extends Notifier<CallStateData> {
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  @override
  CallStateData build() {
    final adapter = ref.watch(sipAdapterProvider);

    adapter.onCallSessionChanged = (session) {
      state = state.copyWith(session: session);
      if (session.isEnded) {
        _cleanupMedia();
      }
    };

    adapter.onRemoteStreamAdded = (remoteStream) {
      _remoteStream = remoteStream;
    };

    ref.onDispose(() {
      _cleanupMedia();
    });

    return const CallStateData();
  }

  Future<bool> startAudioCall(String peer) async {
    final sipState = ref.read(sipControllerProvider);
    if (!sipState.isRegistered) {
      state = CallStateData(
        session: CallSession(
          peer: peer,
          direction: CallDirection.outgoing,
          lifecycle: CallLifecycle.failed,
          failureReason: 'SIP account not registered',
          endedAt: DateTime.now(),
        ),
      );
      return false;
    }

    final permissions = ref.read(relayPermissionsProvider);
    final hasMicPermission = await permissions.isMicrophoneGranted();
    if (!hasMicPermission) {
      state = CallStateData(
        session: CallSession(
          peer: peer,
          direction: CallDirection.outgoing,
          lifecycle: CallLifecycle.failed,
          failureReason: 'Microphone permission denied',
          endedAt: DateTime.now(),
        ),
      );
      return false;
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    } catch (_) {
      state = CallStateData(
        session: CallSession(
          peer: peer,
          direction: CallDirection.outgoing,
          lifecycle: CallLifecycle.failed,
          failureReason: 'Microphone acquisition failed',
          endedAt: DateTime.now(),
        ),
      );
      return false;
    }

    state = CallStateData(
      session: CallSession(
        peer: peer,
        direction: CallDirection.outgoing,
        lifecycle: CallLifecycle.outgoing,
        initiatedAt: DateTime.now(),
      ),
      isMuted: false,
    );

    final adapter = ref.read(sipAdapterProvider);
    final config = ref.read(sipControllerProvider.notifier).currentConfig;
    final domain = config.domain.isNotEmpty ? config.domain : SipAccountConfig.defaultDomain;
    final targetUri = 'sip:${peer.trim()}@$domain';

    final success = await adapter.makeAudioCall(targetUri, mediaStream: _localStream);

    if (!success) {
      await _cleanupMedia();
      state = state.copyWith(
        session: state.session.copyWith(
          lifecycle: CallLifecycle.failed,
          failureReason: 'Failed to initiate call',
          endedAt: DateTime.now(),
        ),
      );
      return false;
    }

    return true;
  }

  Future<bool> answerCall() async {
    final permissions = ref.read(relayPermissionsProvider);
    final hasMicPermission = await permissions.isMicrophoneGranted();
    if (!hasMicPermission) {
      await declineCall();
      return false;
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    } catch (_) {
      await declineCall();
      return false;
    }

    final adapter = ref.read(sipAdapterProvider);
    await adapter.answerCall(mediaStream: _localStream);
    state = state.copyWith(session: state.session.copyWith(lifecycle: CallLifecycle.connecting));
    return true;
  }

  Future<void> declineCall() async {
    final adapter = ref.read(sipAdapterProvider);
    await adapter.hangupCall();
    await _cleanupMedia();
    state = state.copyWith(
      session: state.session.copyWith(lifecycle: CallLifecycle.ended, endedAt: DateTime.now()),
    );
  }

  Future<void> hangup() async {
    final adapter = ref.read(sipAdapterProvider);
    await adapter.hangupCall();
    await _cleanupMedia();
    state = state.copyWith(
      session: state.session.copyWith(lifecycle: CallLifecycle.ended, endedAt: DateTime.now()),
    );
  }

  void toggleMute() {
    final newMute = !state.isMuted;
    final adapter = ref.read(sipAdapterProvider);
    adapter.mute(audio: newMute);

    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !newMute;
      }
    }
    state = state.copyWith(isMuted: newMute);
  }

  void toggleSpeaker() {
    final newSpeaker = !state.isSpeaker;
    try {
      Helper.setSpeakerphoneOn(newSpeaker);
    } catch (_) {}
    state = state.copyWith(isSpeaker: newSpeaker);
  }

  void resetToIdle() {
    _cleanupMedia();
    state = const CallStateData();
  }

  Future<void> _cleanupMedia() async {
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        try {
          track.stop();
        } catch (_) {}
      }
      try {
        await _localStream!.dispose();
      } catch (_) {}
      _localStream = null;
    }
    _remoteStream = null;
  }
}

final callControllerProvider = NotifierProvider<CallController, CallStateData>(CallController.new);
