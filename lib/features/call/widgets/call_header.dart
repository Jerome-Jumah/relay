import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_presentation.dart';

class CallHeader extends StatelessWidget {
  const CallHeader({
    super.key,
    required this.presentation,
    required this.peer,
    this.timer = '04:38',
    this.onBack,
    this.onMore,
  });

  final CallPresentation presentation;
  final String peer;
  final String timer;
  final VoidCallback? onBack;
  final VoidCallback? onMore;

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final backButton = IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_rounded),
      style: IconButton.styleFrom(
        minimumSize: const Size(RelaySizes.minimumTouchTarget, RelaySizes.minimumTouchTarget),
        backgroundColor: presentation == CallPresentation.video
            ? colors.surfaceContainer.withValues(alpha: 0.75)
            : null,
      ),
      onPressed: () => _handleBack(context),
    );

    final moreButton = IconButton(
      tooltip: 'More call options',
      icon: const Icon(Icons.more_horiz_rounded),
      style: IconButton.styleFrom(
        minimumSize: const Size(RelaySizes.minimumTouchTarget, RelaySizes.minimumTouchTarget),
        backgroundColor: presentation == CallPresentation.video
            ? colors.surfaceContainer.withValues(alpha: 0.75)
            : null,
      ),
      onPressed: onMore,
    );

    switch (presentation) {
      case CallPresentation.audio:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            backButton,
            if (onMore != null) moreButton else const SizedBox(width: RelaySizes.minimumTouchTarget),
          ],
        );

      case CallPresentation.video:
        return Row(
          children: [
            backButton,
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm),
                padding: const EdgeInsets.symmetric(vertical: RelaySpacing.xs, horizontal: RelaySpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(RelayRadius.full),
                  border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      peer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      timer,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            moreButton,
          ],
        );

      case CallPresentation.screenShare:
        return Row(
          children: [
            backButton,
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: RelaySpacing.md,
                  vertical: RelaySpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(RelayRadius.full),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.screen_share_rounded, size: 16, color: colors.onPrimaryContainer),
                    const SizedBox(width: RelaySpacing.sm),
                    Text(
                      'Sharing screen',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm),
                      child: Text(
                        '│',
                        style: TextStyle(color: colors.onPrimaryContainer.withValues(alpha: 0.5)),
                      ),
                    ),
                    Text(
                      timer,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onPrimaryContainer,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            moreButton,
          ],
        );
    }
  }
}
