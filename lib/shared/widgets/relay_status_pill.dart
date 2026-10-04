import 'package:flutter/material.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class RelayStatusPill extends StatelessWidget {
  const RelayStatusPill(
    this.label, {
    super.key,
    this.color,
    this.filled = false,
  });

  final String label;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final dotColor = color ?? Theme.of(context).colorScheme.tertiary;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: filled ? 14 : 0,
          vertical: RelaySpacing.sm,
        ),
        decoration: filled
            ? BoxDecoration(
                color: dotColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(RelayRadius.full),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: RelaySpacing.sm,
              height: RelaySpacing.sm,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: RelaySpacing.sm),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
