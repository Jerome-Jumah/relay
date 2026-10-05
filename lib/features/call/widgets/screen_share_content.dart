import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/mock_code_editor.dart';

class ScreenShareContent extends StatelessWidget {
  const ScreenShareContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(RelayRadius.lg),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: const MockCodeEditor(),
    );
  }
}
