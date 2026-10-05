import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/widgets/active_call_stage.dart';
import 'package:relay/features/call/widgets/call_layout.dart';
import 'package:relay/features/call/widgets/call_more_sheet.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    this.peer = '1002',
    this.initialPresentation = CallPresentation.audio,
    this.status = CallUiStatus.connected,
    this.muted = false,
    this.speaker = false,
    this.controlsVisible = true,
  });

  final String peer;
  final CallPresentation initialPresentation;
  final CallUiStatus status;
  final bool muted;
  final bool speaker;
  final bool controlsVisible;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late CallPresentation _presentation = widget.initialPresentation;
  CallPresentation? _presentationBeforeSharing;

  late bool muted = widget.muted;
  late bool speaker = widget.speaker;
  bool camera = true;
  bool flipped = false;
  late bool controlsVisible = widget.controlsVisible;

  @override
  void didUpdateWidget(CallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muted != widget.muted) muted = widget.muted;
    if (oldWidget.speaker != widget.speaker) speaker = widget.speaker;
    if (oldWidget.controlsVisible != widget.controlsVisible) {
      controlsVisible = widget.controlsVisible;
    }
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

  void _endCall() {
    context.go('/call-ended');
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
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) => CallLayout(
    edgeToEdge: true,
    child: ActiveCallStage(
      presentation: _presentation,
      presentationBeforeSharing: _presentationBeforeSharing,
      peer: widget.peer,
      status: widget.status,
      timer: '04:38',
      muted: muted,
      speaker: speaker,
      camera: camera,
      flipped: flipped,
      controlsVisible: controlsVisible,
      onToggleControls: () => setState(() => controlsVisible = !controlsVisible),
      onToggleMute: () => setState(() => muted = !muted),
      onToggleSpeaker: () => setState(() => speaker = !speaker),
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
