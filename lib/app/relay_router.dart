import 'package:go_router/go_router.dart';
import 'package:relay/features/call/call_ended_screen.dart';
import 'package:relay/features/call/call_error_screen.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/call_screen.dart';
import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/incoming_call_screen.dart';
import 'package:relay/features/home/home_screen.dart';
import 'package:relay/features/rtc_lab/rtc_lab_screen.dart';
import 'package:relay/features/settings/settings_screen.dart';
import 'package:relay/features/settings/sip_account_screen.dart';

GoRouter createRelayRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/call',
      builder: (context, state) => CallScreen(
        peer: state.uri.queryParameters['peer'] ?? '1002',
        initialPresentation: switch (state.uri.queryParameters['mode']) {
          'video' => CallPresentation.video,
          'screenShare' || 'screen-sharing' => CallPresentation.screenShare,
          _ => CallPresentation.audio,
        },
        status: switch (state.uri.queryParameters['state']) {
          'connecting' => CallUiStatus.connecting,
          'reconnecting' => CallUiStatus.reconnecting,
          _ => CallUiStatus.connected,
        },
        muted: state.uri.queryParameters['muted'] == '1',
        speaker: state.uri.queryParameters['speaker'] == '1',
        controlsVisible: state.uri.queryParameters['controls'] != '0',
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/sip-account',
      builder: (context, state) => const SipAccountScreen(),
    ),
    GoRoute(
      path: '/rtc-lab',
      builder: (context, state) => RtcLabScreen(
        detailed: state.uri.queryParameters['detail'] == '1',
      ),
    ),
    GoRoute(
      path: '/incoming-call',
      builder: (context, state) => IncomingCallScreen(
        video: state.uri.queryParameters['video'] == '1',
      ),
    ),
    GoRoute(
      path: '/call-ended',
      builder: (context, state) => const CallEndedScreen(),
    ),
    GoRoute(
      path: '/call-error',
      builder: (context, state) => const CallErrorScreen(),
    ),
  ],
);
