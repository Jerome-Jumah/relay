import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    this.peer,
    this.initialPresentation = CallPresentation.audio,
    this.status = CallUiStatus.connected,
    this.muted = false,
    this.speaker = false,
    this.controlsVisible = true,
  });

  final String? peer;
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

  bool camera = true;
  bool flipped = false;
  late bool controlsVisible = widget.controlsVisible;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
      camera = true;
      _presentation = CallPresentation.video;
    });
  }

  void _switchToAudio() {
    HapticFeedback.mediumImpact();
    setState(() {
      camera = false;
      _presentation = CallPresentation.audio;
    });
  }

  void _toggleCamera() {
    setState(() {
      camera = !camera;
      if (!camera) {
        _presentation = CallPresentation.audio;
      }
    });
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
      }
    });

    final callState = ref.watch(callControllerProvider);
    final sessionPeer = callState.session.peer.trim();
    final widgetPeer = widget.peer?.trim() ?? '';
    final peer = sessionPeer.isNotEmpty
        ? sessionPeer
        : (widgetPeer.isNotEmpty ? widgetPeer : 'Unknown');
    final status = callState.session.isActive
        ? CallUiStatus.connected
        : (callState.session.isConnecting ? callState.session.uiStatus : widget.status);
    final timer = callState.session.formattedDuration;
    final muted = callState.isMuted;
    final speaker = callState.isSpeaker;

    return CallLayout(
      edgeToEdge: true,
      child: ActiveCallStage(
        presentation: _presentation,
        presentationBeforeSharing: _presentationBeforeSharing,
        peer: peer,
        status: status,
        timer: timer,
        muted: muted,
        speaker: speaker,
        camera: camera,
        flipped: flipped,
        controlsVisible: controlsVisible,
        onToggleControls: () => setState(() => controlsVisible = !controlsVisible),
        onToggleMute: () => ref.read(callControllerProvider.notifier).toggleMute(),
        onToggleSpeaker: () => ref.read(callControllerProvider.notifier).toggleSpeaker(),
        onToggleCamera: _toggleCamera,
        onToggleFlip: () => setState(() => flipped = !flipped),
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
