import 'package:cue/cue.dart';
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
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

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
                selected: currentMode == mode,
                selectedTileColor: colors.primaryContainer.withValues(alpha: 0.35),
                leading: Icon(
                  icon,
                  color: currentMode == mode ? colors.primary : colors.onSurfaceVariant,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: currentMode == mode ? FontWeight.w600 : FontWeight.w400,
                    color: currentMode == mode ? colors.primary : colors.onSurface,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                trailing: SizedBox.square(
                  dimension: 24,
                  child: currentMode == mode
                      ? (reducedMotion
                          ? Icon(Icons.check_rounded, color: colors.primary)
                          : Cue.onMount(
                              motion: .snappy(),
                              acts: [
                                .fadeIn(),
                                .scale(from: 0.8),
                              ],
                              child: Icon(Icons.check_rounded, color: colors.primary),
                            ))
                      : null,
                ),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (currentMode != mode) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    if (!reducedMotion) {
                      await Future<void>.delayed(const Duration(milliseconds: 140));
                    }
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
