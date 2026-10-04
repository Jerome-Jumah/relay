import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';

class CallControls extends StatelessWidget {
  const CallControls({
    super.key,
    required this.presentation,
    required this.muted,
    required this.onToggleMute,
    this.speaker = false,
    this.onToggleSpeaker,
    this.camera = true,
    this.onToggleCamera,
    this.flipped = false,
    this.onToggleFlip,
    this.onStartVideo,
    this.onStartScreenShare,
    this.onStopScreenShare,
    required this.onMore,
    required this.onEndCall,
  });

  final CallPresentation presentation;
  final bool muted;
  final VoidCallback onToggleMute;
  final bool speaker;
  final VoidCallback? onToggleSpeaker;
  final bool camera;
  final VoidCallback? onToggleCamera;
  final bool flipped;
  final VoidCallback? onToggleFlip;
  final VoidCallback? onStartVideo;
  final VoidCallback? onStartScreenShare;
  final VoidCallback? onStopScreenShare;
  final VoidCallback onMore;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    switch (presentation) {
      case CallPresentation.audio:
        return Column(
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
                  onPressed: onToggleSpeaker ?? () {},
                ),
                RelayCallControl(
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  semanticsLabel: 'Switch to video call',
                  onPressed: onStartVideo ?? () {},
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

      case CallPresentation.video:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RelaySpacing.sm + 2,
            vertical: RelaySpacing.sm + 6,
          ),
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
                  onPressed: onToggleCamera ?? () {},
                ),
                RelayCallControl(
                  size: RelaySizes.callControlSmall,
                  icon: Icons.cameraswitch_outlined,
                  label: 'Flip',
                  semanticsLabel: 'Switch camera',
                  active: flipped,
                  isToggle: true,
                  onPressed: onToggleFlip ?? () {},
                ),
                RelayCallControl(
                  size: RelaySizes.callControlSmall,
                  icon: Icons.screen_share_outlined,
                  label: 'Share',
                  semanticsLabel: 'Start screen sharing',
                  onPressed: onStartScreenShare ?? () {},
                ),
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
          ),
        );

      case CallPresentation.screenShare:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            RelaySpacing.md,
            RelaySpacing.md,
            RelaySpacing.md,
            RelaySpacing.md + 4,
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
              Semantics(
                button: true,
                label: 'Stop screen sharing',
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: RelaySpacing.lg - 2,
                      vertical: RelaySpacing.md,
                    ),
                    minimumSize: const Size(RelaySizes.minimumTouchTarget, 48),
                  ),
                  onPressed: onStopScreenShare,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop sharing'),
                ),
              ),
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
}
