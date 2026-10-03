import 'package:flutter/material.dart';

import '../../app/theme/relay-spacing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(RelaySpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Relay', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: RelaySpacing.small),
              const Text('Foundation ready'),
            ],
          ),
        ),
      ),
    ),
  );
}
