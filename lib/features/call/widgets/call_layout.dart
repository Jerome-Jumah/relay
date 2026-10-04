import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_theme.dart';

class CallLayout extends StatelessWidget {
  const CallLayout({super.key, required this.child, this.edgeToEdge = false});

  final Widget child;
  final bool edgeToEdge;

  @override
  Widget build(BuildContext context) => Theme(
    data: RelayTheme.dark,
    child: Builder(
      builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: edgeToEdge ? child : SafeArea(child: child),
        ),
      ),
    ),
  );
}
