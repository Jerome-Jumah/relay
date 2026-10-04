import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/relay_router.dart';
import 'package:relay/app/theme/relay_theme.dart';
import 'package:relay/features/settings/providers/theme_mode_provider.dart';

class RelayApp extends ConsumerStatefulWidget {
  const RelayApp({super.key});

  @override
  ConsumerState<RelayApp> createState() => _RelayAppState();
}

class _RelayAppState extends ConsumerState<RelayApp> {
  final _router = createRelayRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Relay',
      debugShowCheckedModeBanner: false,
      theme: RelayTheme.light,
      darkTheme: RelayTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
