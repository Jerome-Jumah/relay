import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:relay/app/relay_app.dart';
import 'package:relay/shared/widgets/relay_error_fallback.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
      runApp(const RelayApp());
    },
  );
}
