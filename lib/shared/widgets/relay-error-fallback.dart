import 'package:flutter/material.dart';

import '../../app/theme/relay-spacing.dart';

/// Self-contained so it works even when there is no Theme or Material ancestor.
class RelayErrorFallback extends StatelessWidget {
  const RelayErrorFallback({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFF8F6F2),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.all(RelaySpacing.medium),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Color(0xFF172033), size: 24),
              SizedBox(height: RelaySpacing.small),
              Text(
                'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
