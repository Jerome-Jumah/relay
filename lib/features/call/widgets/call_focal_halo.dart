import 'package:cue/cue.dart';
import 'package:material_ui/material_ui.dart';

import 'package:relay/features/call/call_ui_status.dart';

class CallFocalHalo extends StatelessWidget {
  const CallFocalHalo({super.key, required this.size, required this.status, this.muted = false});

  final double size;
  final CallUiStatus status;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final haloColor = switch (status) {
      CallUiStatus.connected => muted ? colors.outlineVariant : colors.primary,
      CallUiStatus.calling || CallUiStatus.ringing || CallUiStatus.connecting => colors.primary,
      CallUiStatus.reconnecting => colors.secondary,
    };

    final isAnimated = !reducedMotion && !muted;

    final motion = switch (status) {
      CallUiStatus.connected => CueMotion.curved(const Duration(milliseconds: 2800), curve: Curves.easeInOut),
      CallUiStatus.calling ||
      CallUiStatus.ringing ||
      CallUiStatus.connecting => CueMotion.curved(const Duration(milliseconds: 1300), curve: Curves.easeInOut),
      CallUiStatus.reconnecting => CueMotion.curved(const Duration(milliseconds: 1900), curve: Curves.easeInOut),
    };

    final targetScale = switch (status) {
      CallUiStatus.connected => 1.035,
      CallUiStatus.calling || CallUiStatus.ringing || CallUiStatus.connecting => 1.05,
      CallUiStatus.reconnecting => 1.03,
    };

    final baseOpacity = switch (status) {
      CallUiStatus.connected => muted ? 0.25 : 0.45,
      CallUiStatus.calling || CallUiStatus.ringing || CallUiStatus.connecting => 0.35,
      CallUiStatus.reconnecting => 0.4,
    };

    final peakOpacity = switch (status) {
      CallUiStatus.connected => muted ? 0.25 : 0.65,
      CallUiStatus.calling || CallUiStatus.ringing || CallUiStatus.connecting => 0.8,
      CallUiStatus.reconnecting => 0.75,
    };

    final haloSurface = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: haloColor.withValues(alpha: muted ? 0.02 : 0.05),
        border: Border.all(color: haloColor.withValues(alpha: muted ? 0.15 : 0.28), width: 1.5),
        boxShadow: muted ? null : [BoxShadow(color: haloColor.withValues(alpha: 0.08), blurRadius: 18)],
      ),
      child: Center(
        child: Container(
          width: size * 0.86,
          height: size * 0.86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: haloColor.withValues(alpha: muted ? 0.08 : 0.15), width: 1.0),
          ),
        ),
      ),
    );

    if (!isAnimated) {
      return Opacity(opacity: baseOpacity, child: haloSurface);
    }

    return Cue.onMount(
      key: ValueKey(Object.hash(status, muted, reducedMotion)),
      motion: motion,
      repeat: true,
      reverseOnRepeat: true,
      acts: [
        .scale(from: 1.0, to: targetScale),
        .opacity(from: baseOpacity, to: peakOpacity),
      ],
      child: haloSurface,
    );
  }
}
