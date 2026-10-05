import 'package:cue/cue.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/widgets/audio_call_controls.dart';
import 'package:relay/features/call/widgets/screen_share_call_controls.dart';
import 'package:relay/features/call/widgets/video_call_controls.dart';

class CallControls extends StatelessWidget {
  const CallControls({
    super.key,
    required this.presentation,
    this.presentationBeforeSharing,
    required this.muted,
    required this.onToggleMute,
    this.speaker = false,
    this.onToggleSpeaker,
    this.camera = true,
    this.onToggleCamera,
    this.flipped = false,
    this.onToggleFlip,
    this.controlsVisible = true,
    this.onToggleControls,
    this.onStartVideo,
    this.onStartScreenShare,
    this.onStopScreenShare,
    required this.onMore,
    required this.onEndCall,
  });

  final CallPresentation presentation;
  final CallPresentation? presentationBeforeSharing;
  final bool muted;
  final VoidCallback onToggleMute;
  final bool speaker;
  final VoidCallback? onToggleSpeaker;
  final bool camera;
  final VoidCallback? onToggleCamera;
  final bool flipped;
  final VoidCallback? onToggleFlip;
  final bool controlsVisible;
  final VoidCallback? onToggleControls;
  final VoidCallback? onStartVideo;
  final VoidCallback? onStartScreenShare;
  final VoidCallback? onStopScreenShare;
  final VoidCallback onMore;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    final isSharing = presentation == CallPresentation.screenShare;
    final basePresentation = isSharing ? (presentationBeforeSharing ?? CallPresentation.audio) : presentation;
    final isVideo = basePresentation == CallPresentation.video;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Actor(
          acts: [.fadeOut(), if (!reducedMotion) .scale(to: 0.95)],
          child: IgnorePointer(
            ignoring: isSharing,
            child: isVideo
                ? VideoCallControls(
                    muted: muted,
                    camera: camera,
                    flipped: flipped,
                    controlsVisible: controlsVisible,
                    onToggleControls: onToggleControls ?? () {},
                    onToggleMute: onToggleMute,
                    onToggleCamera: onToggleCamera ?? () {},
                    onToggleFlip: onToggleFlip ?? () {},
                    onStartScreenShare: onStartScreenShare ?? () {},
                    onMore: onMore,
                    onEndCall: onEndCall,
                  )
                : AudioCallControls(
                    muted: muted,
                    speaker: speaker,
                    onToggleMute: onToggleMute,
                    onToggleSpeaker: onToggleSpeaker ?? () {},
                    onStartVideo: onStartVideo ?? () {},
                    onMore: onMore,
                    onEndCall: onEndCall,
                  ),
          ),
        ),
        Actor(
          acts: [.fadeIn(), if (!reducedMotion) .scale(from: 0.95)],
          child: IgnorePointer(
            ignoring: !isSharing,
            child: ScreenShareCallControls(
              muted: muted,
              onToggleMute: onToggleMute,
              onStopScreenShare: onStopScreenShare ?? () {},
              onMore: onMore,
              onEndCall: onEndCall,
            ),
          ),
        ),
      ],
    );
  }
}
