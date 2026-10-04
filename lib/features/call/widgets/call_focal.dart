import 'package:flutter/material.dart';

class CallFocal extends StatelessWidget {
  const CallFocal({super.key, this.size = 210});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surfaceContainerHigh,
            border: Border.all(color: colors.outline.withValues(alpha: 0.4)),
          ),
          child: Icon(
            Icons.person_rounded,
            size: size * 0.37,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}
