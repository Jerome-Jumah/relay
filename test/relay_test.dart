import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:relay/app/relay_app.dart';
import 'package:relay/app/relay_router.dart';
import 'package:relay/app/theme/relay_theme.dart';
import 'package:relay/features/call/models/call_lifecycle.dart';
import 'package:relay/features/call/models/call_session.dart';
import 'package:relay/features/call/models/call_state_data.dart';
import 'package:relay/features/call/providers/call_controller.dart';
import 'package:relay/features/call/widgets/relay_call_control.dart';
import 'package:relay/features/home/home_screen.dart';
import 'package:relay/features/rtc_lab/models/rtc_lab_event.dart';
import 'package:relay/features/rtc_lab/providers/rtc_lab_timeline.dart';
import 'package:relay/features/rtc_lab/rtc_lab_screen.dart';
import 'package:relay/features/settings/settings_screen.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:relay/features/sip/sip_controller.dart';
import 'package:relay/shared/permissions/relay_permissions.dart';
import 'package:relay/shared/widgets/relay_settings_tile.dart';

class _TestPermissions extends RelayPermissions {
  const _TestPermissions();

  @override
  Future<PermissionStatus> microphoneStatus() async => PermissionStatus.granted;

  @override
  Future<bool> isMicrophoneGranted() async => true;
}

class _TestSipController extends SipController {
  @override
  SipRegistrationState build() {
    return const SipRegistrationState(
      status: SipRegistrationStatus.registered,
      extension: '1001',
    );
  }
}

class _TestCallController extends CallController {
  @override
  CallStateData build() => const CallStateData();

  @override
  Future<bool> startAudioCall(String peer) async {
    state = CallStateData(
      session: CallSession(
        peer: peer,
        direction: CallDirection.outgoing,
        lifecycle: CallLifecycle.active,
        answeredAt: DateTime.now(),
      ),
    );
    return true;
  }

  @override
  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  @override
  Future<void> hangup() async {
    state = state.copyWith(
      session: state.session.copyWith(
        lifecycle: CallLifecycle.ended,
        endedAt: DateTime.now(),
      ),
    );
  }

  @override
  void resetToIdle() {
    state = const CallStateData();
  }
}

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
    await tester.pumpWidget(const ProviderScope(child: RelayApp()));
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relayPermissionsProvider.overrideWithValue(const _TestPermissions()),
          sipControllerProvider.overrideWith(_TestSipController.new),
          callControllerProvider.overrideWith(_TestCallController.new),
        ],
        child: MaterialApp.router(theme: RelayTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2003');
    await tester.tap(find.text('Audio call'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('2003'), findsAtLeastNWidgets(1));
    expect(find.text('Connected'), findsOneWidget);
    final mute = find.byWidgetPredicate((widget) => widget is RelayCallControl && widget.label == 'Mute').first;
    await tester.tap(mute);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Unmute'), findsAtLeastNWidgets(1));
    final end = find.byWidgetPredicate((widget) => widget is RelayCallControl && widget.label == 'End call').first;
    await tester.ensureVisible(end);
    await tester.tap(find.descendant(of: end, matching: find.byType(InkWell)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Call ended'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });

  testWidgets('rtc lab screen renders timeline events without ColorScheme mismatch', (tester) async {
    final router = createRelayRouter(initialLocation: '/rtc-lab');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relayPermissionsProvider.overrideWithValue(const _TestPermissions()),
          sipControllerProvider.overrideWith(_TestSipController.new),
          callControllerProvider.overrideWith(_TestCallController.new),
        ],
        child: MaterialApp.router(theme: RelayTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(RtcLabScreen));
    final container = ProviderScope.containerOf(element);
    final notifier = container.read(rtcLabTimelineProvider.notifier);

    for (final category in RtcLabEventCategory.values) {
      notifier.record(
        category: category,
        title: 'Event for ${category.name}',
        detail: 'Detail for ${category.name}',
      );
    }

    await tester.pumpAndSettle();

    final timelineFinder = find.text('EVENT TIMELINE');
    await tester.scrollUntilVisible(timelineFinder, 500);
    expect(timelineFinder, findsOneWidget);
    expect(find.text('SIP'), findsOneWidget);
    expect(find.text('ICE'), findsOneWidget);
    expect(find.text('MEDIA'), findsOneWidget);
    expect(find.text('CALL'), findsOneWidget);
    expect(find.text('SHARE'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });

  testWidgets('can navigate from settings to rtc lab with recorded events', (tester) async {
    final router = createRelayRouter(initialLocation: '/settings');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relayPermissionsProvider.overrideWithValue(const _TestPermissions()),
          sipControllerProvider.overrideWith(_TestSipController.new),
          callControllerProvider.overrideWith(_TestCallController.new),
        ],
        child: MaterialApp.router(theme: RelayTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(SettingsScreen));
    final container = ProviderScope.containerOf(element);
    container.read(rtcLabTimelineProvider.notifier).record(
      category: RtcLabEventCategory.sip,
      title: 'Registration OK',
    );

    final rtcLabTileFinder = find.widgetWithText(RelaySettingsTile, 'RTC Lab');
    await tester.scrollUntilVisible(rtcLabTileFinder, 500);
    await tester.tap(rtcLabTileFinder);
    await tester.pumpAndSettle();

    expect(find.byType(RtcLabScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
}
