import 'package:cue/cue.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';

class HomeActionCard extends StatefulWidget {
  const HomeActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool outlined;

  @override
  State<HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<HomeActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Cue.onToggle(
      toggled: _pressed,
      motion: .snappy(),
      acts: [
        if (!reducedMotion) .scale(to: 0.98),
      ],
      child: Material(
        color: widget.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.outlined ? RelayRadius.lg : RelayRadius.full),
          side: widget.outlined ? BorderSide(color: colors.outlineVariant) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onHighlightChanged: (highlighted) => setState(() => _pressed = highlighted),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 22),
            child: Row(
              children: [
                Icon(widget.icon, size: 28, color: widget.foreground),
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(color: widget.foreground, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 25, color: widget.foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
