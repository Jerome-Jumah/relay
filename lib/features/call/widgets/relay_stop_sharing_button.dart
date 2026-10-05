import 'package:cue/cue.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class RelayStopSharingButton extends StatefulWidget {
  const RelayStopSharingButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  State<RelayStopSharingButton> createState() => _RelayStopSharingButtonState();
}

class _RelayStopSharingButtonState extends State<RelayStopSharingButton> {
  bool pressed = false;

  void handlePress() {
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: 'Stop screen sharing',
      child: Cue.onToggle(
        toggled: pressed,
        motion: .snappy(),
        acts: [
          if (!reducedMotion) .scale(to: RelayMotion.pressScale),
        ],
        child: Listener(
          onPointerDown: (_) => setState(() => pressed = true),
          onPointerUp: (_) => setState(() => pressed = false),
          onPointerCancel: (_) => setState(() => pressed = false),
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
            onPressed: handlePress,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop sharing'),
          ),
        ),
      ),
    );
  }
}
