import 'package:flutter/material.dart';

import 'package:relay/app/theme/relay_tokens.dart';

class MockVideoSurface extends StatelessWidget {
  const MockVideoSurface({
    super.key,
    this.selfView = false,
    this.cameraOff = false,
  });

  final bool selfView;
  final bool cameraOff;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = cameraOff
        ? colors.surfaceContainerLowest
        : selfView
        ? colors.surfaceContainerHigh
        : colors.surfaceContainer;

    return Semantics(
      label: selfView ? 'Local video preview' : 'Remote video preview',
      child: ColoredBox(
        color: backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!cameraOff)
              CustomPaint(
                painter: _PortraitPlaceholder(
                  selfView: selfView,
                  colors: colors,
                ),
              ),
            if (cameraOff)
              Center(
                child: Icon(
                  Icons.videocam_off_outlined,
                  color: colors.onSurfaceVariant,
                  size: 32,
                ),
              ),
            if (!selfView)
              Positioned(
                left: RelaySpacing.lg,
                bottom: 160,
                child: Text(
                  'Video preview',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PortraitPlaceholder extends CustomPainter {
  const _PortraitPlaceholder({required this.selfView, required this.colors});

  final bool selfView;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = selfView
        ? colors.surfaceContainerHighest
        : colors.surfaceContainerLow;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.06, 0, size.width * 0.18, size.height),
      paint,
    );

    paint.color = selfView
        ? colors.surfaceContainerLowest
        : colors.surfaceContainerHighest;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.94),
        width: size.width * 1.25,
        height: size.height * 0.72,
      ),
      paint,
    );

    paint.color = selfView
        ? colors.primaryContainer.withValues(alpha: 0.5)
        : colors.outlineVariant;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.41),
        width: size.width * 0.53,
        height: size.height * 0.30,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PortraitPlaceholder oldDelegate) =>
      selfView != oldDelegate.selfView || colors != oldDelegate.colors;
}
