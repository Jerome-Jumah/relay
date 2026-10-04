import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class CallErrorPanel extends StatelessWidget {
  const CallErrorPanel({super.key, required this.onRetry, required this.onDismiss});

  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(RelaySpacing.lg + 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.primaryContainer,
            child: Icon(Icons.screen_share_outlined, size: 28, color: colors.primary),
          ),
          const SizedBox(height: RelaySpacing.lg),
          const Text(
            "Couldn't start screen sharing",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.7),
          ),
          const SizedBox(height: RelaySpacing.md - 2),
          Text(
            "Screen sharing wasn't started.\nTry again.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: RelaySpacing.lg + 4),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(minimumSize: const Size(180, 52)),
            child: const Text('Try again'),
          ),
          const SizedBox(height: RelaySpacing.sm),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(minimumSize: const Size(100, RelaySizes.minimumTouchTarget)),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
