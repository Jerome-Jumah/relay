import 'dart:ui';
import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/widgets/call_focal.dart';
import 'package:relay/shared/widgets/relay_status_pill.dart';

class AudioCallContent extends StatelessWidget {
  const AudioCallContent({
    super.key,
    required this.peer,
    required this.status,
    this.timer = '04:38',
    this.muted = false,
  });

  final String peer;
  final CallUiStatus status;
  final String timer;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          CallFocal(
            size: constraints.maxHeight < 550 ? 150 : 200,
            status: status,
            muted: muted,
          ),
          const SizedBox(height: RelaySpacing.lg + 2),
          Text(
            peer,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w400,
              letterSpacing: -1,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: RelaySpacing.sm + 2),
          Text(
            status == CallUiStatus.connecting ? '00:00' : timer,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: RelaySpacing.sm),
          AnimatedSwitcher(
            duration: reducedMotion ? Duration.zero : RelayDuration.fast,
            child: KeyedSubtree(
              key: ValueKey(status),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RelayStatusPill(
                    status.label,
                    color: switch (status) {
                      CallUiStatus.connected => colors.tertiary,
                      CallUiStatus.connecting => colors.primary,
                      CallUiStatus.reconnecting => colors.secondary,
                    },
                  ),
                  if (status == CallUiStatus.reconnecting)
                    Padding(
                      padding: const EdgeInsets.only(top: RelaySpacing.sm),
                      child: Text(
                        'Trying to restore your connection',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
