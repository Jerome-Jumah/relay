import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:relay/app/relay_app.dart';
import 'package:relay/app/relay_router.dart';
import 'package:relay/app/theme/relay_theme.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';
import 'package:relay/features/home/home_screen.dart';

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'Relay',
      packageName: 'relay',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  testWidgets('app boots at Home with Material 3', (tester) async {
    await tester.pumpWidget(const RelayApp());
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Ready to\nconnect'), findsOneWidget);
    final context = tester.element(find.byType(HomeScreen));
    expect(GoRouter.of(context).routeInformationProvider.value.uri.path, '/');
    expect(Theme.of(context).useMaterial3, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('destination and mute controls update the mock call', (tester) async {
    final router = createRelayRouter();
    await tester.pumpWidget(MaterialApp.router(theme: RelayTheme.light, routerConfig: router));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2003');
    await tester.tap(find.text('Audio call'));
    await tester.pumpAndSettle();
    expect(find.text('2003'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    final mute = find.byWidgetPredicate((widget) => widget is RelayCallControl && widget.label == 'Mute');
    await tester.tap(mute);
    await tester.pumpAndSettle();
    expect(find.text('Unmute'), findsOneWidget);
    final end = find.byWidgetPredicate((widget) => widget is RelayCallControl && widget.label == 'End call');
    await tester.ensureVisible(end);
    await tester.tap(find.descendant(of: end, matching: find.byType(InkWell)));
    await tester.pumpAndSettle();
    expect(find.text('Call ended'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
}
