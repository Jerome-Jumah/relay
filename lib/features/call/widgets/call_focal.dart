import 'package:material_ui/material_ui.dart';

import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/widgets/call_focal_halo.dart';

class CallFocal extends StatelessWidget {
  const CallFocal({
    super.key,
    this.size = 210,
    this.status = CallUiStatus.connected,
    this.muted = false,
  });

  final double size;
  final CallUiStatus status;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final coreSize = size * 0.74;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CallFocalHalo(
                size: size,
                status: status,
                muted: muted,
              ),
              Container(
                width: coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceContainerHigh,
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: coreSize * 0.46,
                  color: muted ? colors.onSurfaceVariant : colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
