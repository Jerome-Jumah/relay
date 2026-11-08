import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/relay_app.dart';
import 'package:relay/shared/widgets/relay_error_fallback.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  void runRelay() {
    ErrorWidget.builder = (_) => const RelayErrorFallback();
    runApp(const ProviderScope(child: RelayApp()));
  }

  // A DSN is an optional public ingestion address, never a SIP/TURN secret.
  const sentryDsn = String.fromEnvironment('RELAY_SENTRY_DSN');
  if (sentryDsn.isEmpty) {
    runRelay();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.environment = const String.fromEnvironment('RELAY_APP_ENV', defaultValue: 'development');
      options.sendDefaultPii = false;
      options.enableNativeCrashHandling = false;
      options.enableAutoSessionTracking = false;
      options.enableAutoNativeBreadcrumbs = false;
      options.enableAutoPerformanceTracing = false;
      options.attachScreenshot = false;
      options.attachViewHierarchy = false;
      options.beforeBreadcrumb = (_, _) => null;
      // Only send a fixed summary. Exceptions and scopes can contain SIP/ICE data.
      options.beforeSend = (event, _) => SentryEvent(
        eventId: event.eventId,
        timestamp: event.timestamp,
        level: event.level,
        release: event.release,
        environment: event.environment,
        message: SentryMessage('Relay application error; inspect locally.'),
      );
    },
    appRunner: runRelay,
  );
}
