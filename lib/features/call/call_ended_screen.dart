import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/call_layout.dart';

class CallEndedScreen extends StatefulWidget {
  const CallEndedScreen({super.key});

  @override
  State<CallEndedScreen> createState() => _CallEndedScreenState();
}

class _CallEndedScreenState extends State<CallEndedScreen> {
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(seconds: 5), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CallLayout(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(RelaySpacing.lg + 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.call_end_rounded,
                color: colors.primary,
                size: 44,
              ),
              const SizedBox(height: RelaySpacing.lg + 4),
              const Text(
                'Call ended',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: RelaySpacing.sm + 4),
              Text(
                '04:38',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 20,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: RelaySpacing.xxl),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
