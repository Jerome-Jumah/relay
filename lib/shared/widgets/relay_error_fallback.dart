import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class RelayErrorFallback extends StatelessWidget {
  const RelayErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surface,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(RelaySpacing.md),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: colors.error, size: 24),
                const SizedBox(height: RelaySpacing.sm),
                Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurface, fontSize: 16, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
