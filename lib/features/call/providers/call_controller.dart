import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:relay/features/call/call_presentation.dart';
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

    adapter.onCallSessionChanged = (session, {hasVideo = false}) {
      state = state.copyWith(
        session: session,
        presentation: hasVideo ? CallPresentation.video : state.presentation,
      );
      if (session.isEnded) {
        _cleanupMedia();
      }
    };

    adapter.onRemoteStreamAdded = (remoteStream) {
      final isSameStream = _remoteStream?.id == remoteStream.id;
      _remoteStream = remoteStream;
      final hasRemoteVideo = remoteStream.getVideoTracks().isNotEmpty;
      if (state.remoteVideoTrackPresent != hasRemoteVideo) {
        state = state.copyWith(remoteVideoTrackPresent: hasRemoteVideo);
      }
      if (!isSameStream) {
        remoteStream.onAddTrack = (track) {
          if (track.kind == 'video') {
            state = state.copyWith(remoteVideoTrackPresent: true);
          }
        };
        remoteStream.onRemoveTrack = (track) {
          if (track.kind == 'video') {
            state = state.copyWith(
              remoteVideoTrackPresent: _remoteStream?.getVideoTracks().isNotEmpty == true,
            );
          }
        };
      }
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
      presentation: CallPresentation.audio,
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

  Future<bool> startVideoCall(String peer) async {
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
        presentation: CallPresentation.video,
      );
      return false;
    }

    final permissions = ref.read(relayPermissionsProvider);
    final hasMic = await permissions.isMicrophoneGranted();
    final hasCam = await permissions.isCameraGranted();
    if (!hasMic || !hasCam) {
      state = CallStateData(
        session: CallSession(
          peer: peer,
          direction: CallDirection.outgoing,
          lifecycle: CallLifecycle.failed,
          failureReason: !hasMic ? 'Microphone permission denied' : 'Camera permission denied',
          endedAt: DateTime.now(),
        ),
        presentation: CallPresentation.video,
      );
      return false;
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'optional': [],
        },
      });
    } catch (_) {
      state = CallStateData(
        session: CallSession(
          peer: peer,
          direction: CallDirection.outgoing,
          lifecycle: CallLifecycle.failed,
          failureReason: 'Camera or microphone acquisition failed',
          endedAt: DateTime.now(),
        ),
        presentation: CallPresentation.video,
      );
      return false;
    }

    final hasLocalVideo = _localStream!.getVideoTracks().isNotEmpty;

    state = CallStateData(
      session: CallSession(
        peer: peer,
        direction: CallDirection.outgoing,
        lifecycle: CallLifecycle.outgoing,
        initiatedAt: DateTime.now(),
      ),
      isMuted: false,
      isSpeaker: true,
      presentation: CallPresentation.video,
      localVideoTrackPresent: hasLocalVideo,
      remoteVideoTrackPresent: false,
      isCameraEnabled: true,
      isFrontCamera: true,
    );

    try {
      Helper.setSpeakerphoneOn(true);
    } catch (_) {}

    final adapter = ref.read(sipAdapterProvider);
    final config = ref.read(sipControllerProvider.notifier).currentConfig;
    final domain = config.domain.isNotEmpty ? config.domain : SipAccountConfig.defaultDomain;
    final targetUri = 'sip:${peer.trim()}@$domain';

    final success = await adapter.makeVideoCall(targetUri, mediaStream: _localStream);

    if (!success) {
      await _cleanupMedia();
      state = state.copyWith(
        session: state.session.copyWith(
          lifecycle: CallLifecycle.failed,
          failureReason: 'Failed to initiate video call',
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

  Future<bool> answerVideoCall() async {
    final permissions = ref.read(relayPermissionsProvider);
    final hasMic = await permissions.isMicrophoneGranted();
    final hasCam = await permissions.isCameraGranted();
    if (!hasMic || !hasCam) {
      await declineCall();
      return false;
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'optional': [],
        },
      });
    } catch (_) {
      await declineCall();
      return false;
    }

    final hasLocalVideo = _localStream!.getVideoTracks().isNotEmpty;

    try {
      Helper.setSpeakerphoneOn(true);
    } catch (_) {}

    final adapter = ref.read(sipAdapterProvider);
    await adapter.answerVideoCall(mediaStream: _localStream);
    state = state.copyWith(
      session: state.session.copyWith(lifecycle: CallLifecycle.connecting),
      presentation: CallPresentation.video,
      localVideoTrackPresent: hasLocalVideo,
      isCameraEnabled: true,
      isFrontCamera: true,
      isSpeaker: true,
    );
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
    if (newMute) {
      adapter.mute(audio: true);
    } else {
      adapter.unmute(audio: true);
    }

    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !newMute;
      }
    }
    state = state.copyWith(isMuted: newMute);
  }

  Future<void> toggleCamera() async {
    final newEnabled = !state.isCameraEnabled;
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = newEnabled;
      }
    }
    final adapter = ref.read(sipAdapterProvider);
    if (newEnabled) {
      adapter.unmute(video: true);
    } else {
      adapter.mute(video: true);
    }
    state = state.copyWith(isCameraEnabled: newEnabled);
  }

  Future<void> flipCamera() async {
    if (_localStream == null) return;
    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;

    try {
      final track = videoTracks.first;
      await Helper.switchCamera(track);
      state = state.copyWith(isFrontCamera: !state.isFrontCamera);
    } catch (_) {}
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
    if (_remoteStream != null) {
      _remoteStream!.onAddTrack = null;
      _remoteStream!.onRemoveTrack = null;
      _remoteStream = null;
    }
    state = state.copyWith(
      localVideoTrackPresent: false,
      remoteVideoTrackPresent: false,
    );
  }
}

final callControllerProvider = NotifierProvider<CallController, CallStateData>(CallController.new);
