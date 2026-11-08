import 'dart:developer' as developer;

/// Console policy: emit fixed event labels, never caller-supplied values.
/// RTC Lab keeps the detailed local counters; console logs omit identities,
/// endpoints, track IDs, exception text, SDP and credentials.
abstract final class RelayLog {
  static void sip(String message) {
    const events = {
      'Unregistering SIP user agent': 'SIP disconnect requested',
      'Transport socket connected': 'SIP transport connected',
      'Transport socket disconnected': 'SIP transport disconnected',
      'Call progress (ringing on remote)': 'Call ringing',
      'Call established (200 OK / ACK)': 'Call established',
      '[RTC Diagnostics] Incoming re-INVITE accepted': 'Remote media transition accepted',
      '[RTC Diagnostics] SIP renegotiation timed out': 'Media renegotiation timed out',
      '[RTC Diagnostics] SIP renegotiation rejected by RTCSession': 'Media renegotiation unavailable',
    };
    final event = events[message];
    if (event != null) _write('relay.sip', event);

    // Match whole enum values. No server-controlled suffix reaches output.
    for (final state in const ['NONE', 'CONNECTING', 'CONNECTED', 'DISCONNECTED']) {
      if (message == 'Transport state changed: TransportStateEnum.$state') {
        _write('relay.sip', 'SIP transport: $state');
      }
    }
    for (final state in const ['NONE', 'REGISTERED', 'REGISTRATION_FAILED', 'UNREGISTERED']) {
      if (message == 'Registration state changed: RegistrationStateEnum.$state') {
        _write('relay.sip', 'SIP registration: $state');
      }
    }
    const prefixes = {
      'Initiating registration for URI:': 'SIP registration requested',
      'Initiating audio call to ': 'Audio call requested',
      'Initiating video call to ': 'Video call requested',
      'Call ended:': 'Call ended',
      'Call failed:': 'Call failed',
      'Registration failed:': 'SIP registration failed',
      'Safe error during unregister:': 'SIP disconnect failed',
      'Safe error on hangup:': 'Call hangup failed',
      '[RTC Diagnostics] SIP renegotiation started': 'Media renegotiation started',
      '[RTC Diagnostics] SIP renegotiation response received:': 'Media renegotiation response received',
      '[RTC Diagnostics] SIP renegotiation error:': 'Media renegotiation failed',
      '[RTC Diagnostics] Error accepting re-INVITE:': 'Remote media transition failed',
    };
    _writeMatchingPrefix('relay.sip', message, prefixes);
    for (final state in const ['CALL_INITIATION', 'CONNECTING', 'PROGRESS', 'ACCEPTED', 'CONFIRMED', 'ENDED', 'FAILED']) {
      if (message.startsWith('Call state changed:') && message.endsWith(', state=CallStateEnum.$state')) {
        _write('relay.sip', 'Call: $state');
      }
    }
    for (final state in const ['New', 'Checking', 'Connected', 'Completed', 'Disconnected', 'Failed', 'Closed', 'Count']) {
      if (message == '[RTC Diagnostics] ICE Connection State: RTCIceConnectionState$state') {
        _write('relay.sip', 'ICE: $state');
      }
    }
  }

  static void call(String message) {
    const results = {
      '[RelayShare] renegotiation complete: success=true': 'Screen sharing renegotiation accepted',
      '[RelayShare] renegotiation complete: success=false': 'Screen sharing renegotiation failed',
      '[RelayShare] Screen sharing active over existing sendrecv video transceiver': 'Screen sharing active',
    };
    final result = results[message];
    if (result != null) _write('relay.call', result);
    const prefixes = {
      '[RTC Diagnostics] Video upgrade requested': 'Video upgrade requested',
      '[RTC Diagnostics] Video upgrade aborted:': 'Video upgrade cancelled',
      '[RTC Diagnostics] Video upgrade failed:': 'Video upgrade failed',
      '[RTC Diagnostics] Video upgrade renegotiation rejected': 'Video upgrade rejected',
      '[RTC Diagnostics] Video upgrade accepted': 'Video upgrade accepted',
      '[RTC Diagnostics] Video downgrade requested': 'Video downgrade requested',
      '[RTC Diagnostics] Video downgrade completed:': 'Video downgrade completed',
      '[RTC Diagnostics] Error clearing video sender on downgrade:': 'Video downgrade sender update failed',
      '[RelayShare] Start screen share requested': 'Screen sharing requested',
      '[RelayShare] MediaProjection consent denied': 'Screen capture consent denied',
      '[RelayShare] MediaProjection consent granted': 'Screen capture consent granted',
      '[RelayShare] capture failed:': 'Screen capture failed',
      '[RelayShare] capture started:': 'Screen capture started',
      '[RelayShare] Stop screen share requested': 'Screen sharing stop requested',
      '[RelayShare] onStopScreenShareRequested': 'Native sharing stop requested',
      '[RelayShare] display track onEnded': 'System capture stop received',
      '[RelayShare] Renegotiation rejected/failed': 'Screen sharing renegotiation failed',
      '[RelayShare] capture ended': 'Screen capture ended',
      '[RelayShare] previous presentation restored:': 'Previous presentation restored',
    };
    _writeMatchingPrefix('relay.call', message, prefixes);
  }

  static void _writeMatchingPrefix(String category, String message, Map<String, String> events) {
    for (final entry in events.entries) {
      if (message.startsWith(entry.key)) {
        _write(category, entry.value);
        return;
      }
    }
  }

  static void _write(String category, String event) => developer.log(event, name: category);
}
