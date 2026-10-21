import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/rtc_lab/models/rtc_lab_snapshot.dart';

class IcePath extends StatelessWidget {
  const IcePath({super.key, required this.snapshot});

  final RtcLabSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!snapshot.isCallActive && !snapshot.hasSelectedCandidatePair) {
      return Container(
        padding: const EdgeInsets.all(RelaySpacing.md + 2),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RelayRadius.lg - 2),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ICE path', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: RelaySpacing.sm),
            Text(
              'No active media path. Connect a call to observe the negotiated ICE candidate pair.',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final localType = snapshot.localCandidateType?.toLowerCase() ?? 'unknown';
    final remoteType = snapshot.remoteCandidateType?.toLowerCase() ?? 'unknown';
    final protocol = snapshot.protocol ?? 'UDP';
    final isRelay = snapshot.isTurnSelected;

    return Semantics(
      label:
          'ICE path: Local $localType $protocol to Remote $remoteType $protocol. '
          '${isRelay ? "Relayed through TURN" : "Direct connection"}.',
      child: Container(
        padding: const EdgeInsets.all(RelaySpacing.md + 2),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(RelayRadius.lg - 2),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ICE path', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (snapshot.roundTripTimeMs != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(RelayRadius.sm),
                    ),
                    child: Text(
                      'RTT ${snapshot.roundTripTimeMs!.round()} ms',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: RelaySpacing.md),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: RelaySpacing.sm,
              children: [
                _CandidateBadge(label: 'Local: $localType', highlight: localType == 'relay', colors: colors),
                Text('→', style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant)),
                _CandidateBadge(
                  label: isRelay ? 'TURN Relay' : 'Direct (P2P)',
                  highlight: isRelay,
                  isPathType: true,
                  colors: colors,
                ),
                Text('→', style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant)),
                _CandidateBadge(label: 'Remote: $remoteType', highlight: remoteType == 'relay', colors: colors),
              ],
            ),
            const SizedBox(height: RelaySpacing.md),
            Row(
              children: [
                Icon(
                  isRelay ? Icons.alt_route_rounded : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: isRelay ? colors.secondary : colors.tertiary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isRelay
                        ? 'Relayed via TURN (relay candidate selected)'
                        : 'Direct connection (TURN configured, but direct path chosen)',
                    style: TextStyle(
                      color: isRelay ? colors.secondary : colors.tertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (snapshot.localAddress != null || snapshot.remoteAddress != null) ...[
              const SizedBox(height: RelaySpacing.sm + 2),
              Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
              const SizedBox(height: RelaySpacing.sm),
              if (snapshot.localAddress != null)
                _AddressRow(label: 'Local address', value: '${snapshot.localAddress} • $protocol'),
              if (snapshot.remoteAddress != null)
                _AddressRow(label: 'Remote address', value: '${snapshot.remoteAddress} • $protocol'),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateBadge extends StatelessWidget {
  const _CandidateBadge({required this.label, required this.highlight, this.isPathType = false, required this.colors});

  final String label;
  final bool highlight;
  final bool isPathType;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight
        ? colors.secondaryContainer
        : isPathType
        ? colors.tertiaryContainer
        : colors.primaryContainer;
    final fgColor = highlight
        ? colors.onSecondaryContainer
        : isPathType
        ? colors.onTertiaryContainer
        : colors.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm + 4, vertical: RelaySpacing.sm + 1),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(RelayRadius.sm + 2)),
      child: Text(
        label,
        style: TextStyle(color: fgColor, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
