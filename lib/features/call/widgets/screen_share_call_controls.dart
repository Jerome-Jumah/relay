import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';
import 'package:relay/features/call/widgets/relay_stop_sharing_button.dart';

class ScreenShareCallControls extends StatelessWidget {
  const ScreenShareCallControls({
    super.key,
    required this.muted,
    required this.onToggleMute,
    required this.onStopScreenShare,
    required this.onMore,
    required this.onEndCall,
  });

  final bool muted;
  final VoidCallback onToggleMute;
  final VoidCallback onStopScreenShare;
  final VoidCallback onMore;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RelaySpacing.md,
        vertical: RelaySpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(RelayRadius.lg + 4),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: RelaySpacing.md,
        runSpacing: RelaySpacing.sm + 6,
        crossAxisAlignment: WrapCrossAlignment.center,
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
          RelayStopSharingButton(onPressed: onStopScreenShare),
          RelayCallControl(
            size: RelaySizes.callControlSmall,
            icon: Icons.more_horiz_rounded,
            label: 'More',
            semanticsLabel: 'More call options',
            onPressed: onMore,
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
    );
  }
}
