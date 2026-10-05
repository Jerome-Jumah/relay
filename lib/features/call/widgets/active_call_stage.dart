import 'package:cue/cue.dart';
import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/widgets/audio_call_content.dart';
import 'package:relay/features/call/widgets/call_controls.dart';
import 'package:relay/features/call/widgets/call_header.dart';
import 'package:relay/features/call/widgets/local_video_preview.dart';
import 'package:relay/features/call/widgets/screen_share_content.dart';
import 'package:relay/features/call/widgets/video_call_content.dart';

class ActiveCallStage extends StatelessWidget {
  const ActiveCallStage({
    super.key,
    required this.presentation,
    this.presentationBeforeSharing,
    required this.peer,
    required this.status,
    this.timer = '04:38',
    required this.muted,
    required this.speaker,
    required this.camera,
    required this.flipped,
    required this.controlsVisible,
    required this.onToggleControls,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleCamera,
    required this.onToggleFlip,
    required this.onStartVideo,
    required this.onStartScreenShare,
    this.onStopScreenShare,
    required this.onMore,
    required this.onEndCall,
    this.onBack,
  });

  final CallPresentation presentation;
  final CallPresentation? presentationBeforeSharing;
  final String peer;
  final CallUiStatus status;
  final String timer;
  final bool muted;
  final bool speaker;
  final bool camera;
  final bool flipped;
  final bool controlsVisible;
  final VoidCallback onToggleControls;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleFlip;
  final VoidCallback onStartVideo;
  final VoidCallback onStartScreenShare;
  final VoidCallback? onStopScreenShare;
  final VoidCallback onMore;
  final VoidCallback onEndCall;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final isSharing = presentation == CallPresentation.screenShare;
    final basePresentation = isSharing
        ? (presentationBeforeSharing ?? CallPresentation.audio)
        : presentation;
    final isVideo = basePresentation == CallPresentation.video;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Cue.onToggle(
      toggled: isSharing,
      motion: .smooth(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Cue.onToggle(
              toggled: isVideo,
              motion: .smooth(),
              child: IgnorePointer(
                ignoring: !isVideo || isSharing,
                child: VideoCallContent(
                  camera: camera,
                  flipped: flipped,
                  onToggleControls: onToggleControls,
                  onToggleFlip: onToggleFlip,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RelaySpacing.md,
                vertical: RelaySpacing.sm + 4,
              ),
              child: Column(
                children: [
                  CallHeader(
                    presentation: presentation,
                    presentationBeforeSharing: presentationBeforeSharing,
                    peer: peer,
                    timer: timer,
                    onBack: onBack,
                    onMore: onMore,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: RelaySpacing.sm + 2),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!isVideo)
                            Positioned.fill(
                              child: Actor(
                                acts: [
                                  .fadeOut(),
                                  if (!reducedMotion) .scale(to: 0.95),
                                ],
                                child: IgnorePointer(
                                  ignoring: isSharing,
                                  child: AudioCallContent(
                                    peer: peer,
                                    status: status,
                                    timer: timer,
                                    muted: muted,
                                  ),
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: Actor(
                              acts: [
                                .fadeIn(),
                                if (!reducedMotion) .scale(from: 0.95),
                              ],
                              child: IgnorePointer(
                                ignoring: !isSharing,
                                child: const ScreenShareContent(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CallControls(
                    presentation: presentation,
                    presentationBeforeSharing: presentationBeforeSharing,
                    muted: muted,
                    speaker: speaker,
                    camera: camera,
                    flipped: flipped,
                    controlsVisible: controlsVisible,
                    onToggleControls: onToggleControls,
                    onToggleMute: onToggleMute,
                    onToggleSpeaker: onToggleSpeaker,
                    onToggleCamera: onToggleCamera,
                    onToggleFlip: onToggleFlip,
                    onStartVideo: onStartVideo,
                    onStartScreenShare: onStartScreenShare,
                    onStopScreenShare: onStopScreenShare,
                    onMore: onMore,
                    onEndCall: onEndCall,
                  ),
                ],
              ),
            ),
          ),
          if (isVideo)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  right: RelaySpacing.md,
                  bottom: 110.0,
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Actor(
                    acts: [
                      if (!reducedMotion) ...[
                        .scale(to: 0.82, alignment: Alignment.bottomRight),
                        .translateY(to: 16),
                      ],
                    ],
                    child: LocalVideoPreview(
                      cameraOff: !camera,
                      flipped: flipped,
                      onTap: onToggleFlip,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
