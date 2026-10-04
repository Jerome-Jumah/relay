import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/widgets/call_controls.dart';
import 'package:relay/features/call/widgets/call_header.dart';
import 'package:relay/features/call/widgets/local_video_preview.dart';
import 'package:relay/features/call/widgets/mock_video_surface.dart';

class VideoCallContent extends StatelessWidget {
  const VideoCallContent({
    super.key,
    required this.peer,
    this.timer = '04:38',
    required this.muted,
    required this.camera,
    required this.flipped,
    required this.controlsVisible,
    required this.onToggleControls,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onToggleFlip,
    required this.onStartScreenShare,
    required this.onMore,
    required this.onEndCall,
    this.onBack,
  });

  final String peer;
  final String timer;
  final bool muted;
  final bool camera;
  final bool flipped;
  final bool controlsVisible;
  final VoidCallback onToggleControls;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleFlip;
  final VoidCallback onStartScreenShare;
  final VoidCallback onMore;
  final VoidCallback onEndCall;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onToggleControls,
          child: const MockVideoSurface(),
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
                  presentation: CallPresentation.video,
                  peer: peer,
                  timer: timer,
                  onBack: onBack,
                  onMore: onMore,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: RelaySpacing.xs,
                      bottom: RelaySpacing.md,
                    ),
                    child: LocalVideoPreview(
                      cameraOff: !camera,
                      flipped: flipped,
                      onTap: onToggleFlip,
                    ),
                  ),
                ),
                if (controlsVisible)
                  CallControls(
                    presentation: CallPresentation.video,
                    muted: muted,
                    camera: camera,
                    flipped: flipped,
                    onToggleMute: onToggleMute,
                    onToggleCamera: onToggleCamera,
                    onToggleFlip: onToggleFlip,
                    onStartScreenShare: onStartScreenShare,
                    onMore: onMore,
                    onEndCall: onEndCall,
                  )
                else
                  IconButton.filled(
                    tooltip: 'Show call controls',
                    onPressed: onToggleControls,
                    icon: const Icon(Icons.touch_app_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerHigh,
                      minimumSize: const Size(
                        RelaySizes.minimumTouchTarget,
                        RelaySizes.minimumTouchTarget,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
