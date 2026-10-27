import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class RelaySettingsTile extends StatelessWidget {
  const RelaySettingsTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.divider = true,
  }) : assert(icon != null || leading != null, 'Either icon or leading must be provided');

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leadingWidget = leading ??
        (icon != null
            ? CircleAvatar(
                radius: 19,
                backgroundColor: colors.surfaceContainer,
                child: Icon(icon, size: 21, color: colors.onSurface),
              )
            : null);

    return Column(
      children: [
        ListTile(
          minTileHeight: RelaySizes.callControl,
          contentPadding: const EdgeInsets.symmetric(horizontal: RelaySpacing.md, vertical: 2),
          leading: leadingWidget,
          title: Text(title, style: const TextStyle(fontSize: 15)),
          trailing:
              trailing ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null) ...[
                    Text(value!, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
                    const SizedBox(width: RelaySpacing.sm),
                  ],
                  if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
          onTap: onTap,
        ),
        if (divider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 72,
            endIndent: 18,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
