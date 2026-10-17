import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/models/call_state_data.dart';
import 'package:relay/features/call/providers/call_controller.dart';
import 'package:relay/features/call/widgets/call_focal.dart';
import 'package:relay/features/call/widgets/call_layout.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';
import 'package:relay/shared/permissions/relay_permissions.dart';
import 'package:relay/shared/widgets/relay_permission_sheet.dart';

class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({super.key, this.video = false});

  final bool video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CallStateData>(callControllerProvider, (previous, next) {
      if (next.session.isEnded) {
        if (context.mounted) {
          context.go('/call-ended');
        }
      }
    });

    final colors = Theme.of(context).colorScheme;
    final callState = ref.watch(callControllerProvider);
    final peer = callState.session.peer.isNotEmpty
        ? callState.session.peer
        : 'Unknown';

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
                    Text(peer, style: const TextStyle(fontSize: 38)),
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
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            await ref
                                .read(callControllerProvider.notifier)
                                .declineCall();
                            if (context.mounted) {
                              context.go('/call-ended');
                            }
                          },
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
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                final permissions = ref.read(relayPermissionsProvider);
                                final micGranted = await RelayPermissionSheet.ensureMicrophone(context, permissions);
                                if (!micGranted) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Microphone permission is required to answer calls.')),
                                    );
                                  }
                                  return;
                                }

                                if (video) {
                                  if (!context.mounted) return;
                                  final camGranted = await RelayPermissionSheet.ensureCamera(context, permissions);
                                  if (!camGranted) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Camera permission is required for video calls.')),
                                      );
                                    }
                                    return;
                                  }
                                  final success = await ref
                                      .read(callControllerProvider.notifier)
                                      .answerVideoCall();
                                  if (success && context.mounted) {
                                    context.go('/call?mode=video');
                                  }
                                } else {
                                  final success = await ref
                                      .read(callControllerProvider.notifier)
                                      .answerCall();
                                  if (success && context.mounted) {
                                    context.go('/call?mode=audio');
                                  }
                                }
                              },
                              child: Semantics(
                                label:
                                    video ? 'Answer video call' : 'Answer call',
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
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final permissions = ref.read(relayPermissionsProvider);
                            final granted = await RelayPermissionSheet.ensureMicrophone(context, permissions);
                            if (!granted) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Microphone permission is required to answer calls.')),
                                );
                              }
                              return;
                            }
                            final success = await ref
                                .read(callControllerProvider.notifier)
                                .answerCall();
                            if (success && context.mounted) {
                              context.go('/call?mode=audio');
                            }
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
