import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/rtc_lab/widgets/diagnostic_section.dart';
import 'package:relay/features/rtc_lab/widgets/ice_path.dart';
import 'package:relay/shared/widgets/relay_section.dart';
import 'package:relay/shared/widgets/relay_settings_tile.dart';

class RtcLabScreen extends StatefulWidget {
  const RtcLabScreen({super.key, this.detailed = false});

  final bool detailed;

  @override
  State<RtcLabScreen> createState() => _RtcLabScreenState();
}

class _RtcLabScreenState extends State<RtcLabScreen> {
  late bool detailed = widget.detailed;
  bool forceTurn = false;
  bool overlay = false;
  bool verbose = false;

  @override
  void didUpdateWidget(RtcLabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detailed != widget.detailed) {
      detailed = widget.detailed;
    }
  }

  Future<void> copyDiagnostics() async {
    await Clipboard.setData(
      const ClipboardData(
        text:
            'Relay · mock diagnostics\nSIP: Registered · WSS · 1001\nWebRTC: Stable · ICE Connected · Peer Connected\nAudio: Opus · Video: VP8 · 1280 × 720\nPath: srflx · Direct · UDP · RTT 32 ms',
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnostics copied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RTC Lab',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RelaySpacing.lg - 2,
            RelaySpacing.sm,
            RelaySpacing.lg - 2,
            RelaySpacing.lg + 4,
          ),
          children: [
            Text(
              "What's happening underneath the call",
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: RelaySpacing.lg),
            Container(
              padding: const EdgeInsets.all(RelaySpacing.md + 4),
              decoration: BoxDecoration(
                color: colors.tertiaryContainer,
                borderRadius: BorderRadius.circular(RelayRadius.lg - 2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: colors.tertiary,
                    size: 30,
                  ),
                  const SizedBox(width: RelaySpacing.md - 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Healthy',
                          style: TextStyle(
                            color: colors.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: RelaySpacing.xs + 1),
                        Text(
                          'Everything looks good',
                          style: TextStyle(
                            color: colors.onTertiaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RelaySpacing.lg + 4),
            const DiagnosticSection(
              title: 'SIP',
              values: {
                'Registration': 'Registered',
                'Transport': 'WSS',
                'Extension': '1001',
              },
            ),
            const DiagnosticSection(
              title: 'WebRTC',
              values: {
                'Signaling': 'Stable',
                'ICE': 'Connected',
                'Peer connection': 'Connected',
              },
            ),
            const DiagnosticSection(
              title: 'Media',
              values: {
                'Audio': 'Opus',
                'Video': 'VP8',
                'Resolution': '1280 × 720',
                'Screen sharing': 'Off',
              },
            ),
            const IcePath(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => detailed = !detailed),
                icon: Icon(
                  detailed
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(detailed ? 'Less detail' : 'Connection details'),
              ),
            ),
            if (detailed)
              const DiagnosticSection(
                title: 'Selected candidate',
                values: {
                  'Type': 'Server reflexive (srflx)',
                  'Local address': '192.168.1.20:54732',
                  'Public address': '41.90.12.14:62014',
                  'Protocol': 'UDP',
                  'RTT': '32 ms',
                },
              ),
            const SizedBox(height: RelaySpacing.sm + 4),
            RelaySection(
              title: 'Experiments',
              children: [
                RelaySettingsTile(
                  icon: Icons.alt_route_rounded,
                  title: 'Force TURN',
                  trailing: Switch(
                    value: forceTurn,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => forceTurn = value);
                    },
                  ),
                ),
                RelaySettingsTile(
                  icon: Icons.insights_outlined,
                  title: 'Show stats overlay',
                  trailing: Switch(
                    value: overlay,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => overlay = value);
                    },
                  ),
                ),
                RelaySettingsTile(
                  icon: Icons.list_alt_rounded,
                  title: 'Verbose RTC events',
                  trailing: Switch(
                    value: verbose,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => verbose = value);
                    },
                  ),
                ),
                RelaySettingsTile(
                  icon: Icons.copy_outlined,
                  title: 'Copy diagnostics',
                  divider: false,
                  onTap: copyDiagnostics,
                ),
              ],
            ),
            if (forceTurn || overlay || verbose)
              Padding(
                padding: const EdgeInsets.only(
                  left: RelaySpacing.sm + 4,
                  bottom: RelaySpacing.lg,
                ),
                child: Text(
                  'Experiment switches are preview controls.\nThe mock connection values stay unchanged.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            RelaySection(
              title: 'Event log',
              children: [
                for (final entry in _events)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RelaySpacing.md + 2,
                      vertical: RelaySpacing.sm + 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          entry.$1,
                          style: TextStyle(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: RelaySpacing.md + 4),
                        Expanded(
                          child: Text(
                            entry.$2,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _events = [
  ('10:43:02', 'INVITE sent'),
  ('10:43:03', 'ICE checking'),
  ('10:43:04', 'Candidate selected'),
  ('10:43:04', 'Peer connected'),
  ('10:43:05', 'Media started'),
];
