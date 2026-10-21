import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/models/call_lifecycle.dart';
import 'package:relay/features/call/providers/call_controller.dart';
import 'package:relay/features/call/widgets/call_layout.dart';

class CallEndedScreen extends ConsumerStatefulWidget {
  const CallEndedScreen({super.key});

  @override
  ConsumerState<CallEndedScreen> createState() => _CallEndedScreenState();
}

class _CallEndedScreenState extends ConsumerState<CallEndedScreen> {
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        context.go('/');
        ref.read(callControllerProvider.notifier).resetToIdle();
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _backToHome() {
    context.go('/');
    ref.read(callControllerProvider.notifier).resetToIdle();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final callState = ref.watch(callControllerProvider);
    final isFailed = callState.session.lifecycle == CallLifecycle.failed;
    final title = isFailed ? (callState.session.failureReason ?? 'Call failed') : 'Call ended';
    final hasDuration = callState.session.answeredAt != null;

    return CallLayout(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(RelaySpacing.lg + 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFailed ? Icons.error_outline_rounded : Icons.call_end_rounded,
                color: isFailed ? colors.error : colors.primary,
                size: 44,
              ),
              const SizedBox(height: RelaySpacing.lg + 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
              ),
              if (callState.session.peer.isNotEmpty) ...[
                const SizedBox(height: RelaySpacing.xs + 2),
                Text(
                  callState.session.peer,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
              if (hasDuration) ...[
                const SizedBox(height: RelaySpacing.sm + 4),
                Text(
                  callState.session.formattedDuration,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 20,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(height: RelaySpacing.xxl),
              TextButton(onPressed: _backToHome, child: const Text('Back to Home')),
            ],
          ),
        ),
      ),
    );
  }
}
