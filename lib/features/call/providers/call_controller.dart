import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/models/call_lifecycle.dart';
import 'package:relay/features/call/models/call_session.dart';
import 'package:relay/features/call/models/call_state_data.dart';
import 'package:relay/features/call/models/requested_call_mode.dart';
import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:relay/features/sip/sip_controller.dart';
import 'package:relay/shared/permissions/relay_permissions.dart';

class CallController extends Notifier<CallStateData> {
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  MediaStream? _cameraStream;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  MediaStream? get cameraStream => _cameraStream;

  @override
  CallStateData build() {
    final adapter = ref.watch(sipAdapterProvider);

    adapter.onCallSessionChanged =
        (session, {hasVideo = false, videoCapability = false, requestedCallMode = RequestedCallMode.audio}) {
          final isIncoming = session.direction == CallDirection.incoming;
          CallPresentation nextPresentation;
          if (session.isEnded) {
            nextPresentation = state.presentation;
          } else if (isIncoming && session.lifecycle == CallLifecycle.incoming) {
            nextPresentation = requestedCallMode == RequestedCallMode.video
                ? CallPresentation.video
                : CallPresentation.audio;
          } else if (state.presentation == CallPresentation.screenShare) {
            nextPresentation = CallPresentation.screenShare;
          } else {
            final activeVideo = state.localVideoActive || (hasVideo && session.isActive);
            nextPresentation = activeVideo ? CallPresentation.video : CallPresentation.audio;
          }

          state = state.copyWith(
            session: session,
            requestedCallMode: requestedCallMode,
            remoteVideoActive: hasVideo,
            videoCapabilityNegotiated: videoCapability || state.videoCapabilityNegotiated,
            presentation: nextPresentation,
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
      // Note: In WebRTC Unified Plan, a dormant transceiver generates a video track.
      // Remote track presence does NOT mean active video presentation.
      // Presentation is governed strictly by localVideoActive || remoteVideoActive.
      if (!isSameStream) {
        remoteStream.onAddTrack = (track) {
          if (track.kind == 'video') {
            _log('[RTC Diagnostics] Remote video track added');
            state = state.copyWith(remoteVideoTrackPresent: true);
          }
        };
        remoteStream.onRemoveTrack = (track) {
          if (track.kind == 'video') {
            final hasRemote = _remoteStream?.getVideoTracks().isNotEmpty == true;
            state = state.copyWith(remoteVideoTrackPresent: hasRemote);
          }
        };
      }
    };

    adapter.onRemoteReinviteAccepted = ({required bool hasVideo}) {
      _log('[RTC Diagnostics] Remote re-INVITE processed: hasVideo=$hasVideo');
      final newRemoteVideoActive = hasVideo;
      final CallPresentation nextPresentation;
      if (state.presentation == CallPresentation.screenShare) {
        nextPresentation = CallPresentation.screenShare;
      } else if (state.localVideoActive || newRemoteVideoActive) {
        nextPresentation = CallPresentation.video;
      } else {
        nextPresentation = CallPresentation.audio;
      }

      _log('[RelayCallUI] remoteVideoActive=$newRemoteVideoActive presentation=$nextPresentation');
      state = state.copyWith(remoteVideoActive: newRemoteVideoActive, presentation: nextPresentation);
    };

    ref.onDispose(() {
      _cleanupMedia(updateState: false);
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
      isSpeaker: false,
      requestedCallMode: RequestedCallMode.audio,
      presentation: CallPresentation.audio,
      localVideoActive: false,
      remoteVideoActive: false,
      videoCapabilityNegotiated: true,
      isCameraEnabled: false,
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
        requestedCallMode: RequestedCallMode.video,
        presentation: CallPresentation.video,
        localVideoActive: false,
        isCameraEnabled: false,
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
        requestedCallMode: RequestedCallMode.video,
        presentation: CallPresentation.video,
        localVideoActive: false,
        isCameraEnabled: false,
      );
      return false;
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'mandatory': {'minWidth': '640', 'minHeight': '480', 'minFrameRate': '30'},
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
        requestedCallMode: RequestedCallMode.video,
        presentation: CallPresentation.video,
        localVideoActive: false,
        isCameraEnabled: false,
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
      requestedCallMode: RequestedCallMode.video,
      presentation: CallPresentation.video,
      localVideoTrackPresent: hasLocalVideo,
      remoteVideoTrackPresent: false,
      localVideoActive: true,
      remoteVideoActive: false,
      videoCapabilityNegotiated: true,
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
    state = state.copyWith(
      session: state.session.copyWith(lifecycle: CallLifecycle.connecting),
      localVideoActive: false,
      remoteVideoActive: false,
      isCameraEnabled: false,
      presentation: CallPresentation.audio,
    );
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
          'mandatory': {'minWidth': '640', 'minHeight': '480', 'minFrameRate': '30'},
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
      localVideoActive: true,
      remoteVideoActive: true,
      videoCapabilityNegotiated: true,
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

  Future<void> _cleanupMedia({bool updateState = true}) async {
    // a. detach/remove camera video track from _localStream
    if (_localStream != null && !identical(_localStream, _cameraStream)) {
      for (final track in _localStream!.getVideoTracks()) {
        try {
          _localStream!.removeTrack(track);
          if (_cameraStream == null) {
            track.stop();
          }
        } catch (_) {}
      }
    }

    // b. stop/dispose _cameraStream
    if (_cameraStream != null) {
      for (final track in _cameraStream!.getTracks()) {
        try {
          track.stop();
        } catch (_) {}
      }
      try {
        await _cameraStream!.dispose();
      } catch (_) {}
      if (identical(_localStream, _cameraStream)) {
        _localStream = null;
      }
      // c. clear _cameraStream
      _cameraStream = null;
    }

    // d. then stop/dispose remaining _localStream tracks (primarily mic)
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
    if (updateState) {
      state = state.copyWith(
        localVideoTrackPresent: false,
        remoteVideoTrackPresent: false,
        localVideoActive: false,
        remoteVideoActive: false,
        videoCapabilityNegotiated: false,
        isCameraEnabled: false,
        isVideoUpgradeInProgress: false,
        presentation: CallPresentation.audio,
      );
    }
  }

  Future<bool> upgradeToVideo() async {
    if (!state.session.isActive || state.isVideoUpgradeInProgress) {
      _log('Cannot upgrade to video: call is not active or upgrade already in progress');
      return false;
    }
    if (state.presentation == CallPresentation.video && state.localVideoTrackPresent) {
      _log('Already in video presentation with local video active');
      return true;
    }

    _log('[RTC Diagnostics] Video upgrade requested');
    _log('[RelayMedia] upgrade begin');
    _log('[RelayMedia] cachedVideoStream=${_cameraStream != null ? "non-null" : "null"}');
    _log('[RelayMedia] cachedVideoTracks=${_cameraStream?.getVideoTracks().length ?? 0}');
    state = state.copyWith(isVideoUpgradeInProgress: true);

    // Clean up any stale camera stream if one lingered
    if (_cameraStream != null) {
      for (final t in _cameraStream!.getVideoTracks()) {
        try {
          t.stop();
        } catch (_) {}
      }
      try {
        await _cameraStream!.dispose();
      } catch (_) {}
      _cameraStream = null;
    }

    // 1. Request camera permission
    final permissions = ref.read(relayPermissionsProvider);
    final permStatus = await permissions.requestCamera();
    if (!permStatus.isGranted) {
      _log('[RTC Diagnostics] Video upgrade aborted: camera permission denied');
      state = state.copyWith(isVideoUpgradeInProgress: false);
      return false;
    }

    // 2. Acquire camera video track (keeping existing mic stream)
    MediaStream videoMediaStream;
    try {
      videoMediaStream = await navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'facingMode': 'user',
          'mandatory': {'minWidth': '640', 'minHeight': '480', 'minFrameRate': '30'},
          'optional': [],
        },
      });
    } catch (e) {
      _log('[RTC Diagnostics] Video upgrade failed: camera acquisition error: $e');
      state = state.copyWith(isVideoUpgradeInProgress: false);
      return false;
    }

    final videoTracks = videoMediaStream.getVideoTracks();
    _log('[RelayMedia] acquiredStreamTracks=${videoTracks.length}');
    if (videoTracks.isEmpty) {
      _log('[RTC Diagnostics] Video upgrade failed: acquired stream has no video track');
      try {
        await videoMediaStream.dispose();
      } catch (_) {}
      state = state.copyWith(isVideoUpgradeInProgress: false);
      return false;
    }
    final videoTrack = videoTracks.first;
    _cameraStream = videoMediaStream;
    _log('[RelayMedia] acquiredVideoTrack state=${videoTrack.enabled ? "live" : "ended"} id=${videoTrack.id}');
    _log('[RTC Diagnostics] Local video track acquired: ${videoTrack.id}');

    final adapter = ref.read(sipAdapterProvider);
    final pc = adapter.peerConnection;
    if (pc == null) {
      _log('[RTC Diagnostics] Video upgrade failed: PeerConnection is null');
      try {
        videoTrack.stop();
      } catch (_) {}
      try {
        await videoMediaStream.dispose();
      } catch (_) {}
      _cameraStream = null;
      state = state.copyWith(isVideoUpgradeInProgress: false);
      return false;
    }

    // 3. Find existing pre-negotiated video transceiver / sender
    RTCRtpTransceiver? videoTransceiver;
    try {
      final transceivers = await pc.getTransceivers();
      for (final t in transceivers) {
        if (t.sender.track?.kind == 'video' || t.receiver.track?.kind == 'video') {
          videoTransceiver = t;
          break;
        }
      }
      if (videoTransceiver == null && transceivers.length > 1) {
        videoTransceiver = transceivers[1];
      }
    } catch (e) {
      _log('[RTC Diagnostics] Error inspecting transceivers: $e');
    }

    if (videoTransceiver == null) {
      _log('[RTC Diagnostics] Video upgrade failed: No video transceiver found');
      try {
        videoTrack.stop();
      } catch (_) {}
      try {
        await videoMediaStream.dispose();
      } catch (_) {}
      _cameraStream = null;
      state = state.copyWith(isVideoUpgradeInProgress: false);
      return false;
    }

    final senderTrackBefore = '${videoTransceiver.sender.track?.id}/${videoTransceiver.sender.track != null ? (videoTransceiver.sender.track!.enabled ? "live" : "ended") : "none"}';
    _log('[RelayMedia] senderTrackBefore=$senderTrackBefore');

    _log('[RTC Diagnostics] Reusing pre-negotiated video sender');
    String oldDirStr = 'recvonly';
    try {
      final oldDir = await videoTransceiver.getDirection();
      oldDirStr = _directionToString(oldDir);
    } catch (_) {}

    await videoTransceiver.sender.replaceTrack(videoTrack);
    await videoTransceiver.setDirection(TransceiverDirection.SendRecv);
    _log('[RTC Diagnostics] Video transceiver direction changed: $oldDirStr -> sendrecv');

    final senderTrackAfter = '${videoTransceiver.sender.track?.id}/${videoTransceiver.sender.track != null ? (videoTransceiver.sender.track!.enabled ? "live" : "ended") : "none"}';
    _log('[RelayMedia] senderTrackAfter=$senderTrackAfter');

    if (_localStream == null) {
      _localStream = videoMediaStream;
    } else if (!_localStream!.getVideoTracks().contains(videoTrack)) {
      _localStream!.addTrack(videoTrack);
    }

    // 4. Trigger SIP renegotiation
    _log('[RTC Diagnostics] Video upgrade re-INVITE started');
    final renegSuccess = await adapter.renegotiate(voiceOnly: false);

    // Check local SDP for video
    try {
      final localDesc = await pc.getLocalDescription();
      final sdp = localDesc?.sdp ?? '';
      final hasVideoInSdp = sdp.contains('m=video') && !RegExp(r'm=video 0\b').hasMatch(sdp);
      _log('[RTC Diagnostics] Local SDP ${hasVideoInSdp ? 'now contains video' : 'does not contain video'}');
    } catch (_) {}

    if (!renegSuccess) {
      _log('[RTC Diagnostics] Video upgrade renegotiation rejected / failed. Rolling back.');
      await videoTransceiver.sender.replaceTrack(null);
      await videoTransceiver.setDirection(TransceiverDirection.RecvOnly);
      _log('[RTC Diagnostics] Video transceiver direction changed: sendrecv -> recvonly');
      _localStream?.removeTrack(videoTrack);
      try {
        videoTrack.stop();
      } catch (_) {}
      try {
        await videoMediaStream.dispose();
      } catch (_) {}
      _cameraStream = null;

      final CallPresentation fallbackPresentation;
      if (state.presentation == CallPresentation.screenShare) {
        fallbackPresentation = CallPresentation.screenShare;
      } else if (state.remoteVideoActive) {
        fallbackPresentation = CallPresentation.video;
      } else {
        fallbackPresentation = CallPresentation.audio;
      }

      state = state.copyWith(
        isVideoUpgradeInProgress: false,
        localVideoActive: false,
        isCameraEnabled: false,
        presentation: fallbackPresentation,
      );
      return false;
    }

    _log('[RTC Diagnostics] Video upgrade accepted');
    try {
      Helper.setSpeakerphoneOn(true);
    } catch (_) {}

    final CallPresentation successPresentation = state.presentation == CallPresentation.screenShare
        ? CallPresentation.screenShare
        : CallPresentation.video;

    state = state.copyWith(
      isVideoUpgradeInProgress: false,
      presentation: successPresentation,
      localVideoTrackPresent: true,
      localVideoActive: true,
      isCameraEnabled: true,
      isFrontCamera: true,
      isSpeaker: true,
    );

    return true;
  }

  Future<bool> downgradeToAudio() async {
    final adapter = ref.read(sipAdapterProvider);
    if (!state.session.isActive) return false;
    _log('[RTC Diagnostics] Video downgrade requested');
    _log('[RelayMedia] downgrade begin');

    // 1. Clear video sender track and return transceiver to dormant state
    final pc = adapter.peerConnection;
    if (pc != null) {
      try {
        final transceivers = await pc.getTransceivers();
        RTCRtpTransceiver? videoTransceiver;
        for (final t in transceivers) {
          if (t.sender.track?.kind == 'video' || t.receiver.track?.kind == 'video') {
            videoTransceiver = t;
            break;
          }
        }
        if (videoTransceiver == null && transceivers.length > 1) {
          videoTransceiver = transceivers[1];
        }

        if (videoTransceiver != null) {
          final senderTrackBefore = '${videoTransceiver.sender.track?.id}/${videoTransceiver.sender.track != null ? (videoTransceiver.sender.track!.enabled ? "live" : "ended") : "none"}';
          _log('[RelayMedia] senderTrackBefore=$senderTrackBefore');
          await videoTransceiver.sender.replaceTrack(null);
          _log('[RelayMedia] replaceTrack(null) complete');
          await videoTransceiver.setDirection(TransceiverDirection.RecvOnly);
          _log('[RTC Diagnostics] Video transceiver returned to dormant state');
        } else {
          final senders = await pc.getSenders();
          for (final s in senders) {
            if (s.track?.kind == 'video') {
              final senderTrackBefore = '${s.track?.id}/${s.track != null ? (s.track!.enabled ? "live" : "ended") : "none"}';
              _log('[RelayMedia] senderTrackBefore=$senderTrackBefore');
              await s.replaceTrack(null);
              _log('[RelayMedia] replaceTrack(null) complete');
            }
          }
        }
      } catch (e) {
        _log('[RTC Diagnostics] Error clearing video sender on downgrade: $e');
      }
    }

    // 2. Remove video track from _localStream
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        try {
          _localStream!.removeTrack(track);
        } catch (_) {}
      }
    }

    // 3. Stop and dispose dedicated camera stream
    if (_cameraStream != null) {
      for (final track in _cameraStream!.getVideoTracks()) {
        _log('[RelayMedia] stopping video track=${track.id}/${track.enabled ? "live" : "ended"}');
        try {
          track.stop();
        } catch (_) {}
      }
      _log('[RelayMedia] disposing camera stream');
      try {
        await _cameraStream!.dispose();
      } catch (_) {}
      _cameraStream = null;
      _log('[RelayMedia] cached camera references cleared');
    }

    // 4. Renegotiate with voiceOnly: true
    _log('[RTC Diagnostics] Renegotiation started for video downgrade');
    final success = await adapter.renegotiate(voiceOnly: true);

    // 4. Update presentation
    final CallPresentation nextPresentation;
    if (state.presentation == CallPresentation.screenShare) {
      nextPresentation = CallPresentation.screenShare;
    } else if (state.remoteVideoActive) {
      nextPresentation = CallPresentation.video;
    } else {
      nextPresentation = CallPresentation.audio;
    }

    state = state.copyWith(
      localVideoTrackPresent: false,
      localVideoActive: false,
      isCameraEnabled: false,
      presentation: nextPresentation,
    );

    _log('[RTC Diagnostics] Video downgrade completed: presentation=$nextPresentation');
    return success;
  }

  String _directionToString(TransceiverDirection? dir) {
    switch (dir) {
      case TransceiverDirection.SendRecv:
        return 'sendrecv';
      case TransceiverDirection.SendOnly:
        return 'sendonly';
      case TransceiverDirection.RecvOnly:
        return 'recvonly';
      case TransceiverDirection.Inactive:
        return 'inactive';
      case TransceiverDirection.Stopped:
        return 'stopped';
      case null:
        return 'recvonly';
    }
  }

  void _log(String message) {
    developer.log('[RelayCall] $message', name: 'relay.call');
  }
}

final callControllerProvider = NotifierProvider<CallController, CallStateData>(CallController.new);
