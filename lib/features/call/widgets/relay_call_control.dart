import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class RelayCallControl extends StatefulWidget {
  const RelayCallControl({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.destructive = false,
    this.size = RelaySizes.callControl,
    this.showLabel = true,
    this.isToggle = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;
  final bool destructive;
  final double size;
  final bool showLabel;
  final bool isToggle;

  @override
  State<RelayCallControl> createState() => _RelayCallControlState();
}

class _RelayCallControlState extends State<RelayCallControl> {
  bool pressed = false;

  void handlePress() {
    if (widget.destructive) {
      HapticFeedback.heavyImpact();
    } else if (widget.isToggle) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = widget.destructive
        ? colors.error
        : widget.active
        ? colors.primary
        : colors.surfaceContainerHigh;
    final foreground = widget.destructive
        ? colors.onError
        : widget.active
        ? colors.onPrimary
        : colors.onSurface;

    return Semantics(
      button: true,
      toggled: widget.isToggle ? widget.active : null,
      onTap: handlePress,
      label: widget.label,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: pressed ? 0.94 : 1.0,
              duration: RelayDuration.fast,
              child: AnimatedContainer(
                duration: RelayDuration.fast,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onHighlightChanged: (value) =>
                        setState(() => pressed = value),
                    onTap: handlePress,
                    child: Icon(
                      widget.icon,
                      color: foreground,
                      size: widget.size <= 50 ? 23 : 28,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: RelaySpacing.sm + 1),
              Text(
                widget.label,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
