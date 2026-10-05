import 'dart:ui';

import 'package:cue/cue.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_presentation.dart';

class CallHeader extends StatelessWidget {
  const CallHeader({
    super.key,
    required this.presentation,
    this.presentationBeforeSharing,
    required this.peer,
    this.timer = '04:38',
    this.onBack,
    this.onMore,
  });

  final CallPresentation presentation;
  final CallPresentation? presentationBeforeSharing;
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
    final isSharing = presentation == CallPresentation.screenShare;
    final basePresentation = isSharing
        ? (presentationBeforeSharing ?? CallPresentation.audio)
        : presentation;
    final isVideo = basePresentation == CallPresentation.video;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final backButton = IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_rounded),
      style: IconButton.styleFrom(
        minimumSize: const Size(RelaySizes.minimumTouchTarget, RelaySizes.minimumTouchTarget),
        backgroundColor: colors.surfaceContainer.withValues(alpha: isVideo || isSharing ? 0.75 : 0.0),
      ),
      onPressed: () => _handleBack(context),
    );

    final moreButton = IconButton(
      tooltip: 'More call options',
      icon: const Icon(Icons.more_horiz_rounded),
      style: IconButton.styleFrom(
        minimumSize: const Size(RelaySizes.minimumTouchTarget, RelaySizes.minimumTouchTarget),
        backgroundColor: colors.surfaceContainer.withValues(alpha: isVideo || isSharing ? 0.75 : 0.0),
      ),
      onPressed: onMore,
    );

    final showBasePill = isVideo;

    return Row(
      children: [
        backButton,
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Actor(
                acts: [
                  .fadeOut(),
                  if (!reducedMotion) .scale(to: 0.95),
                ],
                child: IgnorePointer(
                  ignoring: isSharing || !showBasePill,
                  child: Opacity(
                    opacity: showBasePill ? 1.0 : 0.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        vertical: RelaySpacing.xs,
                        horizontal: RelaySpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(RelayRadius.full),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.3),
                        ),
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
                ),
              ),
              Actor(
                acts: [
                  .fadeIn(),
                  if (!reducedMotion) .scale(from: 0.95),
                ],
                child: IgnorePointer(
                  ignoring: !isSharing,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: RelaySpacing.md,
                      vertical: RelaySpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(RelayRadius.full),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
              ),
            ],
          ),
        ),
        if (onMore != null) moreButton else const SizedBox(width: RelaySizes.minimumTouchTarget),
      ],
    );
  }
}
