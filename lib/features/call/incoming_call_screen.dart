import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/call_focal.dart';
import 'package:relay/features/call/widgets/call_layout.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key, this.video = false});

  final bool video;

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
                padding: const EdgeInsets.all(RelaySpacing.lg + 4),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    const CallFocal(),
                    const SizedBox(height: RelaySpacing.lg + 4),
                    const Text('1002', style: TextStyle(fontSize: 38)),
                    const SizedBox(height: RelaySpacing.sm + 4),
                    Text(
                      video ? 'Incoming video call' : 'Incoming call',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(flex: 3),
                    const SizedBox(height: RelaySpacing.xxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RelayCallControl(
                          icon: Icons.call_end_rounded,
                          label: 'Decline',
                          destructive: true,
                          size: 72,
                          onPressed: () => context.go('/call-ended'),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                shape: const CircleBorder(),
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                minimumSize: const Size(72, 72),
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                context.go(video ? '/video-call' : '/audio-call');
                              },
                              child: Semantics(
                                label: video
                                    ? 'Answer video call'
                                    : 'Answer call',
                                child: Icon(
                                  video
                                      ? Icons.videocam_rounded
                                      : Icons.call_rounded,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: RelaySpacing.sm + 1),
                            Text(
                              'Answer',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (video)
                      Padding(
                        padding: const EdgeInsets.only(top: RelaySpacing.lg),
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.go('/audio-call');
                          },
                          child: const Text('Answer without video'),
                        ),
                      ),
                    const SizedBox(height: RelaySpacing.lg + 4),
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
