import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class ScreenShareContent extends StatelessWidget {
  const ScreenShareContent({super.key, this.peer});

  final String? peer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: RelaySpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: RelaySpacing.lg,
          vertical: RelaySpacing.xl,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(RelayRadius.lg),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.screen_share_rounded,
                size: 44,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: RelaySpacing.lg),
            Text(
              'Your screen is visible to the other participant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
                letterSpacing: -0.2,
                height: 1.3,
              ),
            ),
            const SizedBox(height: RelaySpacing.sm),
            Text(
              'Sharing your entire screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
