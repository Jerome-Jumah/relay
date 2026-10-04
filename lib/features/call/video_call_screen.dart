import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/call_layout.dart';
import 'package:relay/features/call/widgets/call_more_sheet.dart';
import 'package:relay/features/call/widgets/mock_video_surface.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    this.peer = '1002',
    this.controlsVisible = true,
  });

  final String peer;
  final bool controlsVisible;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool muted = false;
  bool camera = true;
  bool flipped = false;
  late bool visible = widget.controlsVisible;

  @override
  void didUpdateWidget(VideoCallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlsVisible != widget.controlsVisible) {
      visible = widget.controlsVisible;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CallLayout(
      edgeToEdge: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => setState(() => visible = !visible),
            child: const MockVideoSurface(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RelaySpacing.md,
                vertical: RelaySpacing.sm + 4,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filled(
                        tooltip: 'Back to Home',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colors.surfaceContainer.withValues(alpha: 0.6),
                        ),
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.peer,
                              style: TextStyle(
                                fontSize: 18,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              '04:38',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'More call options',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colors.surfaceContainer.withValues(alpha: 0.6),
                        ),
                        onPressed: () => CallMoreSheet.show(context),
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: flipped
                          ? 'Rear camera preview selected'
                          : 'Self view',
                      child: Container(
                        width: 104,
                        height: MediaQuery.sizeOf(context).height < 650
                            ? 112
                            : 148,
                        margin: const EdgeInsets.only(
                          right: RelaySpacing.xs,
                          bottom: RelaySpacing.md,
                        ),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(RelayRadius.md + 2),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: MockVideoSurface(
                          selfView: true,
                          cameraOff: !camera,
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: RelayDuration.normal,
                    child: visible
                        ? Container(
                            key: const ValueKey('controls'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: RelaySpacing.sm + 2,
                              vertical: RelaySpacing.sm + 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHigh
                                  .withValues(alpha: 0.95),
                              borderRadius:
                                  BorderRadius.circular(RelayRadius.lg + 4),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) => Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: constraints.maxWidth >= 350 ? 10 : 5,
                                runSpacing: RelaySpacing.sm + 6,
                                children: [
                                  RelayCallControl(
                                    size: RelaySizes.callControlSmall,
                                    icon: muted
                                        ? Icons.mic_off_rounded
                                        : Icons.mic_rounded,
                                    label: muted ? 'Unmute' : 'Mute',
                                    active: muted,
                                    isToggle: true,
                                    onPressed: () =>
                                        setState(() => muted = !muted),
                                  ),
                                  RelayCallControl(
                                    size: RelaySizes.callControlSmall,
                                    icon: camera
                                        ? Icons.videocam_rounded
                                        : Icons.videocam_off_rounded,
                                    label: 'Camera',
                                    active: camera,
                                    isToggle: true,
                                    onPressed: () =>
                                        setState(() => camera = !camera),
                                  ),
                                  RelayCallControl(
                                    size: RelaySizes.callControlSmall,
                                    icon: Icons.cameraswitch_outlined,
                                    label: 'Flip',
                                    active: flipped,
                                    isToggle: true,
                                    onPressed: () =>
                                        setState(() => flipped = !flipped),
                                  ),
                                  RelayCallControl(
                                    size: RelaySizes.callControlSmall,
                                    icon: Icons.screen_share_outlined,
                                    label: 'Share',
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      context.push('/screen-sharing');
                                    },
                                  ),
                                  RelayCallControl(
                                    size: RelaySizes.callControlSmall,
                                    icon: Icons.more_horiz_rounded,
                                    label: 'More',
                                    onPressed: () =>
                                        CallMoreSheet.show(context),
                                  ),
                                  RelayCallControl(
                                    size: RelaySizes.callControlSmall,
                                    icon: Icons.call_end_rounded,
                                    label: 'End',
                                    destructive: true,
                                    onPressed: () =>
                                        context.go('/call-ended'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : IconButton.filled(
                            key: const ValueKey('show-controls'),
                            tooltip: 'Show call controls',
                            onPressed: () => setState(() => visible = true),
                            icon: const Icon(Icons.touch_app_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: colors.surfaceContainerHigh,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
