import 'dart:async';

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
  late CallPresentation _presentation = widget.initialPresentation;
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
    }
  }

  void _syncStreams() {
    if (!_renderersInitialized) return;
    final controller = ref.read(callControllerProvider.notifier);
    final local = controller.localStream;
    final remote = controller.remoteStream;

    if (_localRenderer.srcObject != local) {
      _localRenderer.srcObject = local;
    }
    if (_remoteRenderer.srcObject != remote) {
      _remoteRenderer.srcObject = remote;
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
      _presentationBeforeSharing = _presentation;
      _presentation = CallPresentation.screenShare;
    });
  }

  void _stopScreenShare() {
    setState(() {
      _presentation = _presentationBeforeSharing ?? CallPresentation.audio;
      _presentationBeforeSharing = null;
    });
  }

  void _switchToVideo() {
    HapticFeedback.mediumImpact();
    setState(() {
      _presentation = CallPresentation.video;
    });
  }

  void _switchToAudio() {
    HapticFeedback.mediumImpact();
    setState(() {
      _presentation = CallPresentation.audio;
    });
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
    CallMoreSheet.show(
      context,
      presentation: _presentation,
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
      _syncStreams();
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
    final camera = callState.isCameraEnabled;
    final isFrontCamera = callState.isFrontCamera;
    final flipped = !isFrontCamera;

    final effectivePresentation = _presentationBeforeSharing == null && widget.initialPresentation == CallPresentation.audio && callState.presentation == CallPresentation.video
        ? CallPresentation.video
        : _presentation;

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
        hasRemoteVideo: callState.remoteVideoTrackPresent,
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
