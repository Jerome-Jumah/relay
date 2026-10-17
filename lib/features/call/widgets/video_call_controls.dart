import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';

class VideoCallControls extends StatelessWidget {
  const VideoCallControls({
    super.key,
    required this.muted,
    required this.camera,
    required this.flipped,
    this.speaker = true,
    required this.controlsVisible,
    required this.onToggleControls,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onToggleFlip,
    this.onToggleSpeaker,
    this.onStartScreenShare,
    this.onMore,
    required this.onEndCall,
  });

  final bool muted;
  final bool camera;
  final bool flipped;
  final bool speaker;
  final bool controlsVisible;
  final VoidCallback onToggleControls;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleFlip;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onStartScreenShare;
  final VoidCallback? onMore;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!controlsVisible) {
      return IconButton.filled(
        tooltip: 'Show call controls',
        onPressed: onToggleControls,
        icon: const Icon(Icons.touch_app_outlined),
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceContainerHigh,
          minimumSize: const Size(RelaySizes.minimumTouchTarget, RelaySizes.minimumTouchTarget),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm + 2, vertical: RelaySpacing.sm + 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(RelayRadius.lg + 4),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: constraints.maxWidth >= 350 ? 10 : 5,
          runSpacing: RelaySpacing.sm + 6,
          children: [
            RelayCallControl(
              size: RelaySizes.callControlSmall,
              icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: muted ? 'Unmute' : 'Mute',
              semanticsLabel: muted ? 'Unmute microphone' : 'Mute microphone',
              active: muted,
              isToggle: true,
              onPressed: onToggleMute,
            ),
            RelayCallControl(
              size: RelaySizes.callControlSmall,
              icon: camera ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              label: 'Camera',
              semanticsLabel: camera ? 'Turn camera off' : 'Turn camera on',
              active: camera,
              isToggle: true,
              onPressed: onToggleCamera,
            ),
            RelayCallControl(
              size: RelaySizes.callControlSmall,
              icon: Icons.cameraswitch_outlined,
              label: 'Flip',
              semanticsLabel: 'Switch camera',
              active: flipped,
              isToggle: true,
              rotateOnToggle: true,
              onPressed: onToggleFlip,
            ),
            if (onToggleSpeaker != null)
              RelayCallControl(
                size: RelaySizes.callControlSmall,
                icon: speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                label: 'Speaker',
                semanticsLabel: speaker ? 'Turn speakerphone off' : 'Turn speakerphone on',
                active: speaker,
                isToggle: true,
                onPressed: onToggleSpeaker!,
              ),
            RelayCallControl(
              size: RelaySizes.callControlSmall,
              icon: Icons.call_end_rounded,
              label: 'End',
              semanticsLabel: 'End call',
              destructive: true,
              onPressed: onEndCall,
            ),
          ],
        ),
      ),
    );
  }
}
