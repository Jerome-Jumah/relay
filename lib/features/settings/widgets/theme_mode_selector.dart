import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/settings/providers/theme_mode_provider.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const SafeArea(
      child: ThemeModeSelector(),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final currentMode = ref.watch(themeModeProvider);

    final options = const [
      (ThemeMode.system, 'System', 'Matches system settings', Icons.brightness_auto_outlined),
      (ThemeMode.light, 'Light', 'Always use light theme', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Dark', 'Always use dark theme', Icons.dark_mode_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RelaySpacing.md,
        RelaySpacing.xs,
        RelaySpacing.md,
        RelaySpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RelaySpacing.sm,
              vertical: RelaySpacing.sm,
            ),
            child: Text(
              'Theme',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          for (final (mode, title, subtitle, icon) in options)
            Semantics(
              selected: currentMode == mode,
              button: true,
              label: '$title theme',
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RelayRadius.md),
                ),
                leading: Icon(icon, color: colors.onSurfaceVariant),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: currentMode == mode ? FontWeight.w600 : FontWeight.w400,
                    color: colors.onSurface,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                trailing: currentMode == mode
                    ? Icon(Icons.check_rounded, color: colors.primary)
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
            ),
        ],
      ),
    );
  }
}
