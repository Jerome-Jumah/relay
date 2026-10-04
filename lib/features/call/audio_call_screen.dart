import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/widgets/call_focal.dart';
import 'package:relay/features/call/widgets/call_layout.dart';
import 'package:relay/features/call/widgets/call_more_sheet.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';
import 'package:relay/shared/widgets/relay_status_pill.dart';

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({
    super.key,
    this.peer = '1002',
    this.status = CallUiStatus.connected,
    this.muted = false,
    this.speaker = false,
  });

  final String peer;
  final CallUiStatus status;
  final bool muted;
  final bool speaker;

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late bool muted = widget.muted;
  late bool speaker = widget.speaker;

  @override
  void didUpdateWidget(AudioCallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muted != widget.muted) muted = widget.muted;
    if (oldWidget.speaker != widget.speaker) speaker = widget.speaker;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CallLayout(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RelaySpacing.lg,
                  RelaySpacing.sm + 4,
                  RelaySpacing.lg,
                  RelaySpacing.lg,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back to Home',
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        onPressed: () => context.go('/'),
                      ),
                    ),
                    const Spacer(flex: 2),
                    CallFocal(size: constraints.maxHeight < 650 ? 170 : 220),
                    const SizedBox(height: RelaySpacing.lg + 4),
                    Text(
                      widget.peer,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: RelaySpacing.sm + 4),
                    Text(
                      widget.status == CallUiStatus.connecting
                          ? '00:00'
                          : '04:38',
                      style: TextStyle(
                        fontSize: 23,
                        color: colors.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: RelaySpacing.sm),
                    RelayStatusPill(
                      widget.status.label,
                      color: widget.status == CallUiStatus.connected
                          ? colors.tertiary
                          : colors.primary,
                    ),
                    if (widget.status == CallUiStatus.reconnecting)
                      Padding(
                        padding: const EdgeInsets.only(top: RelaySpacing.sm),
                        child: Text(
                          'Trying to restore your connection',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const Spacer(flex: 3),
                    Padding(
                      padding: const EdgeInsets.only(top: RelaySpacing.xl + 4),
                      child: Wrap(
                        spacing: RelaySpacing.lg + 4,
                        runSpacing: RelaySpacing.md,
                        alignment: WrapAlignment.center,
                        children: [
                          RelayCallControl(
                            icon: muted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            label: muted ? 'Unmute' : 'Mute',
                            active: muted,
                            isToggle: true,
                            onPressed: () => setState(() => muted = !muted),
                          ),
                          RelayCallControl(
                            icon: Icons.volume_up_rounded,
                            label: 'Speaker',
                            active: speaker,
                            isToggle: true,
                            onPressed: () =>
                                setState(() => speaker = !speaker),
                          ),
                          RelayCallControl(
                            icon: Icons.more_horiz_rounded,
                            label: 'More',
                            onPressed: () => CallMoreSheet.show(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RelaySpacing.xl - 2),
                    RelayCallControl(
                      icon: Icons.call_end_rounded,
                      label: 'End call',
                      destructive: true,
                      size: RelaySizes.callControlLarge,
                      onPressed: () => context.go('/call-ended'),
                    ),
                    const SizedBox(height: RelaySpacing.sm + 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
