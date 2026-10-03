import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'shared/widgets/relay-error-fallback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.environment = dotenv.env['APP_ENV'] ?? 'development';
    },
    appRunner: () {
      ErrorWidget.builder = (_) => const RelayErrorFallback();
      runApp(const ProviderScope(child: RelayApp()));
    },
  );
}
