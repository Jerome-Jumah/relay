import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/app.dart';
import 'package:relay/app/theme/relay-theme.dart';
import 'package:relay/features/home/home-screen.dart';

void main() {
  testWidgets('app boots at the Home route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RelayApp()));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Relay'), findsOneWidget);
    expect(find.text('Foundation ready'), findsOneWidget);
    final context = tester.element(find.byType(HomeScreen));
    expect(GoRouter.of(context).routeInformationProvider.value.uri.path, '/');
    expect(Theme.of(context).useMaterial3, isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('light and dark themes build the placeholder', (tester) async {
    for (final theme in [RelayTheme.light, RelayTheme.dark]) {
      await tester.pumpWidget(
        MaterialApp(theme: theme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(HomeScreen));
      expect(Theme.of(context).brightness, theme.brightness);
      expect(Theme.of(context).textTheme.headlineLarge, isNotNull);
      expect(theme.useMaterial3, isTrue);
      expect(tester.takeException(), isNull);
    }
  });
}
