import 'package:go_router/go_router.dart';
import 'package:relay/features/call/audio_call_screen.dart';
import 'package:relay/features/call/call_ended_screen.dart';
import 'package:relay/features/call/call_error_screen.dart';
import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/incoming_call_screen.dart';
import 'package:relay/features/call/screen_sharing_screen.dart';
import 'package:relay/features/call/video_call_screen.dart';
import 'package:relay/features/home/home_screen.dart';
import 'package:relay/features/rtc_lab/rtc_lab_screen.dart';
import 'package:relay/features/settings/settings_screen.dart';

GoRouter createRelayRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/audio-call',
      builder: (context, state) => AudioCallScreen(
        peer: state.uri.queryParameters['peer'] ?? '1002',
        status: switch (state.uri.queryParameters['state']) {
          'connecting' => CallUiStatus.connecting,
          'reconnecting' => CallUiStatus.reconnecting,
          _ => CallUiStatus.connected,
        },
        muted: state.uri.queryParameters['muted'] == '1',
        speaker: state.uri.queryParameters['speaker'] == '1',
      ),
    ),
    GoRoute(
      path: '/video-call',
      builder: (context, state) => VideoCallScreen(
        peer: state.uri.queryParameters['peer'] ?? '1002',
        controlsVisible: state.uri.queryParameters['controls'] != '0',
      ),
    ),
    GoRoute(
      path: '/screen-sharing',
      builder: (context, state) => const ScreenSharingScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
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
