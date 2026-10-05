import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';

class AudioCallControls extends StatelessWidget {
  const AudioCallControls({
    super.key,
    required this.muted,
    required this.speaker,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onStartVideo,
    required this.onMore,
    required this.onEndCall,
  });

  final bool muted;
  final bool speaker;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onStartVideo;
  final VoidCallback onMore;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        spacing: RelaySpacing.lg,
        runSpacing: RelaySpacing.md,
        alignment: WrapAlignment.center,
        children: [
          RelayCallControl(
            icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: muted ? 'Unmute' : 'Mute',
            semanticsLabel: muted ? 'Unmute microphone' : 'Mute microphone',
            active: muted,
            isToggle: true,
            onPressed: onToggleMute,
          ),
          RelayCallControl(
            icon: Icons.volume_up_rounded,
            label: 'Speaker',
            semanticsLabel: speaker ? 'Turn speaker off' : 'Use speaker',
            active: speaker,
            isToggle: true,
            onPressed: onToggleSpeaker,
          ),
          RelayCallControl(
            icon: Icons.videocam_rounded,
            label: 'Video',
            semanticsLabel: 'Switch to video call',
            onPressed: onStartVideo,
          ),
          RelayCallControl(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            semanticsLabel: 'More call options',
            onPressed: onMore,
          ),
        ],
      ),
      const SizedBox(height: RelaySpacing.xl - 2),
      RelayCallControl(
        icon: Icons.call_end_rounded,
        label: 'End call',
        semanticsLabel: 'End call',
        destructive: true,
        size: RelaySizes.callControlLarge,
        onPressed: onEndCall,
      ),
    ],
  );
}
