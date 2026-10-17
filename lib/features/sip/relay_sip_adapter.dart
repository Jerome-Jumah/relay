import 'dart:developer' as developer;

import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:sip_ua/sip_ua.dart';

class RelaySipAdapter implements SipUaHelperListener {
  RelaySipAdapter({SIPUAHelper? helper}) : _helper = helper ?? SIPUAHelper() {
    _helper.addSipUaHelperListener(this);
  }

  final SIPUAHelper _helper;

  void Function(SipRegistrationStatus status, {String? errorMessage})?
  onStatusChanged;

  bool get isRegistered => _helper.registered;

  Future<void> register(SipAccountConfig config) async {
    _log('Initiating registration for URI: ${config.sipUri}');
    _log('Signaling WebSocket URL: ${config.webSocketUrl}');
    _log('Authorization user: ${config.authorizationUser}');

    onStatusChanged?.call(SipRegistrationStatus.connecting);

    final uaSettings = UaSettings();
    uaSettings.transportType = TransportType.WS;
    uaSettings.webSocketUrl = config.webSocketUrl.trim();
    uaSettings.uri = config.sipUri;
    uaSettings.authorizationUser = config.authorizationUser;
    uaSettings.password = config.password;
    uaSettings.displayName = config.extension.trim();
    uaSettings.register = true;

    await _helper.start(uaSettings);
  }

  Future<void> unregister() async {
    _log('Unregistering SIP user agent');
    try {
      if (_helper.registered) {
        await _helper.unregister();
      }
      _helper.stop();
    } catch (e) {
      _log('Safe error during unregister: $e');
    }
    onStatusChanged?.call(SipRegistrationStatus.disconnected);
  }

  void dispose() {
    _helper.removeSipUaHelperListener(this);
    try {
      _helper.stop();
    } catch (_) {}
  }

  @override
  void transportStateChanged(TransportState state) {
    _log('Transport state changed: ${state.state}');
    switch (state.state) {
      case TransportStateEnum.CONNECTING:
        onStatusChanged?.call(SipRegistrationStatus.connecting);
      case TransportStateEnum.CONNECTED:
        _log('Transport socket connected');
      case TransportStateEnum.DISCONNECTED:
        _log('Transport socket disconnected');
        final error = state.cause?.cause;
        onStatusChanged?.call(
          SipRegistrationStatus.disconnected,
          errorMessage: error,
        );
      case TransportStateEnum.NONE:
        break;
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    _log('Registration state changed: ${state.state}');
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        onStatusChanged?.call(SipRegistrationStatus.registered);
      case RegistrationStateEnum.REGISTRATION_FAILED:
        final safeReason = _formatSafeError(state.cause);
        _log('Registration failed: $safeReason');
        onStatusChanged?.call(
          SipRegistrationStatus.failed,
          errorMessage: safeReason,
        );
      case RegistrationStateEnum.UNREGISTERED:
        onStatusChanged?.call(SipRegistrationStatus.disconnected);
      case RegistrationStateEnum.NONE:
      case null:
        onStatusChanged?.call(SipRegistrationStatus.idle);
    }
  }

  @override
  void callStateChanged(Call call, CallState state) {}

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  String _formatSafeError(dynamic cause) {
    if (cause == null) return 'Registration failed';
    try {
      final statusCode = cause.status_code;
      if (statusCode == 401 || statusCode == 403) {
        return 'Authentication failed. Please check extension and password.';
      }
      final reasonPhrase = cause.reason_phrase;
      if (reasonPhrase != null && reasonPhrase.toString().isNotEmpty) {
        return reasonPhrase.toString();
      }
      final causeText = cause.cause;
      if (causeText != null && causeText.toString().isNotEmpty) {
        return causeText.toString();
      }
    } catch (_) {}
    return 'Registration failed';
  }

  void _log(String message) {
    developer.log('[RelaySIP] $message', name: 'relay.sip');
  }
}
