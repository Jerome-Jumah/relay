import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/models/call_state_data.dart';
import 'package:relay/features/call/providers/call_controller.dart';
import 'package:relay/features/call/widgets/active_call_stage.dart';
import 'package:relay/features/call/widgets/call_layout.dart';
import 'package:relay/features/call/widgets/call_more_sheet.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    super.key,
    this.initialPresentation = CallPresentation.audio,
    this.status = CallUiStatus.connected,
    this.muted = false,
    this.speaker = false,
    this.controlsVisible = true,
  });
  final CallPresentation initialPresentation;
  final CallUiStatus status;
  final bool muted;
  final bool speaker;
  final bool controlsVisible;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  CallPresentation? _presentationBeforeSharing;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  late bool controlsVisible = widget.controlsVisible;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (mounted) {
      setState(() {
        _renderersInitialized = true;
      });
      _syncStreams();
      if (ref.read(callControllerProvider).localVideoActive) {
        final local = ref.read(callControllerProvider.notifier).localStream;
        _localRenderer.srcObject = local;
        developer.log('[RelayCallUI] localRenderer.srcObject assigned on init: id=${local?.id}', name: 'relay.call');
      }
    }
  }

  void _syncStreams({bool force = false}) {
    if (!_renderersInitialized) return;
    final controller = ref.read(callControllerProvider.notifier);
    final remote = controller.remoteStream;

    if (_remoteRenderer.srcObject != remote || force) {
      _remoteRenderer.srcObject = remote;
      developer.log('[RelayCallUI] remoteRenderer.srcObject assigned: id=${remote?.id}', name: 'relay.call');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _startScreenShare() {
    HapticFeedback.mediumImpact();
    setState(() {
      _presentationBeforeSharing = ref.read(callControllerProvider).presentation;
    });
  }

  void _stopScreenShare() {
    setState(() {
      _presentationBeforeSharing = null;
    });
  }

  Future<void> _switchToVideo() async {
    final callState = ref.read(callControllerProvider);
    if (callState.isVideoUpgradeInProgress) return;
    HapticFeedback.mediumImpact();
    final success = await ref.read(callControllerProvider.notifier).upgradeToVideo();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not switch to video. Audio call continues.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _switchToAudio() async {
    HapticFeedback.mediumImpact();
    await ref.read(callControllerProvider.notifier).downgradeToAudio();
  }

  Future<void> _toggleCamera() async {
    HapticFeedback.mediumImpact();
    await ref.read(callControllerProvider.notifier).toggleCamera();
  }

  Future<void> _toggleFlip() async {
    HapticFeedback.mediumImpact();
    await ref.read(callControllerProvider.notifier).flipCamera();
  }

  Future<void> _endCall() async {
    await ref.read(callControllerProvider.notifier).hangup();
    if (mounted) {
      context.go('/call-ended');
    }
  }

  void _showMore() {
    final callState = ref.read(callControllerProvider);
    final effectivePresentation = _presentationBeforeSharing != null
        ? CallPresentation.screenShare
        : callState.presentation;
    CallMoreSheet.show(
      context,
      presentation: effectivePresentation,
      onStartScreenShare: _startScreenShare,
      onStopScreenShare: _stopScreenShare,
      onSwitchToAudio: _switchToAudio,
      onSwitchToVideo: _switchToVideo,
    );
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallStateData>(callControllerProvider, (previous, next) {
      if (next.session.isEnded) {
        if (mounted) {
          context.go('/call-ended');
        }
        return;
      }

      final wasLocalActive = previous?.localVideoActive ?? false;
      final isLocalActive = next.localVideoActive;
      if (!wasLocalActive && isLocalActive) {
        final local = ref.read(callControllerProvider.notifier).localStream;
        _localRenderer.srcObject = local;
        developer.log('[RelayCallUI] localRenderer.srcObject bound: id=${local?.id}', name: 'relay.call');
      } else if (wasLocalActive && !isLocalActive) {
        _localRenderer.srcObject = null;
        developer.log('[RelayCallUI] localRenderer.srcObject cleared on downgrade', name: 'relay.call');
      }

      final remoteBecameActive = previous?.remoteVideoActive != true && next.remoteVideoActive;
      _syncStreams(force: remoteBecameActive);
    });

    final callState = ref.watch(callControllerProvider);
    _syncStreams();

    final sessionPeer = callState.session.peer.trim();
    final peer = sessionPeer.isNotEmpty ? sessionPeer : 'Unknown';
    final status = callState.session.isActive
        ? CallUiStatus.connected
        : (callState.session.isConnecting ? callState.session.uiStatus : widget.status);
    final timer = callState.session.formattedDuration;
    final muted = callState.isMuted;
    final speaker = callState.isSpeaker;
    final camera = callState.isCameraEnabled && callState.localVideoActive;
    final isFrontCamera = callState.isFrontCamera;
    final flipped = !isFrontCamera;

    final effectivePresentation = _presentationBeforeSharing != null
        ? CallPresentation.screenShare
        : callState.presentation;

    developer.log(
      '[RelayCallUI] effectivePresentation=$effectivePresentation remoteVideoActive=${callState.remoteVideoActive} localVideoActive=${callState.localVideoActive}',
      name: 'relay.call',
    );

    return CallLayout(
      edgeToEdge: true,
      child: ActiveCallStage(
        presentation: effectivePresentation,
        presentationBeforeSharing: _presentationBeforeSharing,
        peer: peer,
        status: status,
        timer: timer,
        muted: muted,
        speaker: speaker,
        camera: camera,
        flipped: flipped,
        isFrontCamera: isFrontCamera,
        localRenderer: _renderersInitialized ? _localRenderer : null,
        remoteRenderer: _renderersInitialized ? _remoteRenderer : null,
        hasRemoteVideo: callState.remoteVideoActive,
        controlsVisible: controlsVisible,
        onToggleControls: () => setState(() => controlsVisible = !controlsVisible),
        onToggleMute: () => ref.read(callControllerProvider.notifier).toggleMute(),
        onToggleSpeaker: () => ref.read(callControllerProvider.notifier).toggleSpeaker(),
        onToggleCamera: _toggleCamera,
        onToggleFlip: _toggleFlip,
        onStartVideo: _switchToVideo,
        onStartScreenShare: _startScreenShare,
        onStopScreenShare: _stopScreenShare,
        onMore: _showMore,
        onEndCall: _endCall,
        onBack: _handleBack,
      ),
    );
  }
}
