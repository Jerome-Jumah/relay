import 'package:material_ui/material_ui.dart';
import 'package:relay/app/relay_router.dart';
import 'package:relay/app/theme/relay_theme.dart';

class RelayApp extends StatefulWidget {
  const RelayApp({super.key});

  @override
  State<RelayApp> createState() => _RelayAppState();
}

class _RelayAppState extends State<RelayApp> {
  final _router = createRelayRouter();

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
    themeMode: ThemeMode.light,
    routerConfig: _router,
  );
}
