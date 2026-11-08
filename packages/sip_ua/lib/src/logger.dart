import 'package:logger/logger.dart';

Logger logger = Log();

class Log extends Logger {
  Log() : super(printer: MyLogPrinter('.'));

  static Level _loggingLevel = Level.debug;
  static set loggingLevel(Level loggingLevel) => _loggingLevel = loggingLevel;
}

/// Relay's default printer emits reviewed constant labels only. It never
/// forwards message arguments, exception values or stack traces. Redacting
/// selected headers is insufficient because SDP and parser errors also carry
/// authentication material. A custom logger must enforce the same policy.
class MyLogPrinter extends LogPrinter {
  MyLogPrinter(this.currentWorkingDirectory);

  final String currentWorkingDirectory;

  static const _events = <String, String>{
    'WebSocket connecting': 'Transport connecting',
    'TCP connecting': 'Transport connecting',
    'Transport connected': 'Transport connected',
    'Transport connecting': 'Transport connecting',
    'Socket Transport close()': 'Transport closing',
    'call connecting': 'Call connecting',
    'call is in progress': 'Call progressing',
    'call accepted': 'Call accepted',
    'call confirmed': 'Call confirmed',
    'session ended': 'Call ended',
    'session failed': 'Call failed',
    'renegotiate()': 'Media renegotiation requested',
    'SIP grammar parse failed': 'SIP grammar parse failed',
    'WebSocket send skipped: disconnected': 'Transport send skipped: disconnected',
  };

  @override
  List<String> log(LogEvent event) {
    if (Log._loggingLevel.index > event.level.index) return const [];
    final message = event.message;
    final safeEvent = message is String ? _events[message] : null;
    if (safeEvent != null) return ['[sip_ua] $safeEvent'];
    if (event.level.index >= Level.warning.index) {
      return const ['[sip_ua] Stack warning/error; sensitive details withheld'];
    }
    return const [];
  }
}
