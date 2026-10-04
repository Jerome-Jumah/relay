import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/call_layout.dart';
import 'package:relay/features/call/widgets/call_more_sheet.dart';
import 'package:relay/features/call/widgets/mock_code_editor.dart';
import 'package:relay/features/call/widgets/mock_video_surface.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';

class ScreenSharingScreen extends StatefulWidget {
  const ScreenSharingScreen({super.key});

  @override
  State<ScreenSharingScreen> createState() => _ScreenSharingScreenState();
}

class _ScreenSharingScreenState extends State<ScreenSharingScreen> {
  bool muted = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CallLayout(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SizedBox(
            height: constraints.maxHeight.clamp(
              560 + (MediaQuery.textScalerOf(context).scale(14) / 14 - 1) * 440,
              double.infinity,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RelaySpacing.sm + 2,
                    RelaySpacing.sm + 2,
                    RelaySpacing.sm + 2,
                    RelaySpacing.sm + 6,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back to call',
                        onPressed: () => context.go('/audio-call'),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: RelaySpacing.sm + 4,
                            vertical: RelaySpacing.sm + 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(RelayRadius.full),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: RelaySpacing.sm,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: colors.primary,
                              ),
                              const Text(
                                'Sharing screen',
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                '│',
                                style: TextStyle(color: colors.outlineVariant),
                              ),
                              const Text(
                                '05:12',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'More call options',
                        onPressed: () => CallMoreSheet.show(context),
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned.fill(child: MockCodeEditor()),
                      Positioned(
                        right: RelaySpacing.md,
                        bottom: 48,
                        child: Container(
                          width: 82,
                          height: 108,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(RelayRadius.md - 1),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: const MockVideoSurface(selfView: true),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RelaySpacing.md,
                    RelaySpacing.lg - 2,
                    RelaySpacing.md,
                    RelaySpacing.md + 4,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: RelaySpacing.lg - 2,
                    runSpacing: RelaySpacing.sm + 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RelayCallControl(
                        size: 58,
                        icon: muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: muted ? 'Unmute' : 'Mute',
                        active: muted,
                        isToggle: true,
                        onPressed: () => setState(() => muted = !muted),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: RelaySpacing.lg - 2,
                            vertical: RelaySpacing.md + 4,
                          ),
                          minimumSize: const Size(48, 58),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.go('/audio-call');
                        },
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop sharing'),
                      ),
                      RelayCallControl(
                        size: 58,
                        icon: Icons.more_horiz_rounded,
                        label: 'More',
                        onPressed: () => CallMoreSheet.show(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
