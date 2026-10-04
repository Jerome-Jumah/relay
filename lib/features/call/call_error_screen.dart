import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:relay/features/call/widgets/call_error_panel.dart';

class CallErrorScreen extends StatelessWidget {
  const CallErrorScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Screen sharing')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: CallErrorPanel(
            onRetry: () => context.go('/screen-sharing'),
            onDismiss: () => context.go('/'),
          ),
        ),
      ),
    ),
  );
}
