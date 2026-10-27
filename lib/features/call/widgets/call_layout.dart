import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class CallLayout extends StatelessWidget {
  const CallLayout({super.key, required this.child, this.edgeToEdge = false});

  final Widget child;
  final bool edgeToEdge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overlayStyle = isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: edgeToEdge ? child : SafeArea(child: child),
      ),
    );
  }
}

