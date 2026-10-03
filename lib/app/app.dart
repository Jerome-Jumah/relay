import 'package:flutter/material.dart';

import 'router/app-router.dart';
import 'theme/relay-theme.dart';

class RelayApp extends StatefulWidget {
  const RelayApp({super.key});

  @override
  State<RelayApp> createState() => _RelayAppState();
}

class _RelayAppState extends State<RelayApp> {
  final _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Relay',
    debugShowCheckedModeBanner: false,
    theme: RelayTheme.light,
    darkTheme: RelayTheme.dark,
    routerConfig: _router,
  );
}
