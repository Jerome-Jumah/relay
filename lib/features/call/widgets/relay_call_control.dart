import 'package:cue/cue.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

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
    this.rotateOnToggle = false,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;
  final bool destructive;
  final double size;
  final bool showLabel;
  final bool isToggle;
  final bool rotateOnToggle;
  final String? semanticsLabel;

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
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveLabel = widget.semanticsLabel ?? widget.label;
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
    final iconSize = widget.size <= 50 ? 23.0 : 28.0;
    final targetPressScale = widget.destructive
        ? RelayMotion.destructivePressScale
        : RelayMotion.pressScale;

    return Semantics(
      button: true,
      toggled: widget.isToggle ? widget.active : null,
      onTap: handlePress,
      label: effectiveLabel,
      child: Tooltip(
        message: effectiveLabel,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Cue.onToggle(
                toggled: pressed,
                motion: .snappy(),
                acts: [
                  if (!reducedMotion) .scale(to: targetPressScale),
                ],
                child: SizedBox.square(
                  dimension: widget.size,
                  child: AnimatedContainer(
                    duration: reducedMotion ? Duration.zero : RelayDuration.fast,
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
                        onHighlightChanged: (value) => setState(() => pressed = value),
                        onTap: handlePress,
                        child: Center(
                          child: widget.rotateOnToggle
                              ? Cue.onToggle(
                                  toggled: widget.active,
                                  motion: .smooth(),
                                  acts: [
                                    if (!reducedMotion) .rotate(to: 180),
                                  ],
                                  child: Icon(
                                    widget.icon,
                                    color: foreground,
                                    size: iconSize,
                                  ),
                                )
                              : Cue.onChange(
                                  value: Object.hash(widget.icon, widget.active),
                                  motion: .snappy(),
                                  acts: [
                                    if (!reducedMotion) .scale(from: 0.88),
                                    if (!reducedMotion) .fadeIn(from: 0.6),
                                  ],
                                  child: Icon(
                                    widget.icon,
                                    color: foreground,
                                    size: iconSize,
                                  ),
                                ),
                        ),
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
      ),
    );
  }
}
