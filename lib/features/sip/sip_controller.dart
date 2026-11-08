import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/features/rtc_lab/models/rtc_lab_event.dart';
import 'package:relay/features/rtc_lab/providers/rtc_lab_timeline.dart';
import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:relay/features/sip/relay_sip_adapter.dart';
import 'package:relay/features/sip/sip_storage.dart';

class SipController extends Notifier<SipRegistrationState> {
  late final RelaySipAdapter _adapter;
  late final SipStorage _storage;
  SipAccountConfig _currentConfig = const SipAccountConfig();

  SipAccountConfig get currentConfig => _currentConfig;
  RelaySipAdapter get adapter => _adapter;

  @override
  SipRegistrationState build() {
    _storage = const SipStorage();
    _adapter = RelaySipAdapter();

    _adapter.onStatusChanged = (status, {errorMessage}) {
      state = state.copyWith(status: status, extension: _currentConfig.extension, errorMessage: errorMessage);
      final title = switch (status) {
        SipRegistrationStatus.registered => 'SIP Registered (${_currentConfig.extension})',
        SipRegistrationStatus.connecting => 'SIP Connecting…',
        SipRegistrationStatus.failed => 'SIP Registration Failed',
        SipRegistrationStatus.disconnected => 'SIP Disconnected',
        SipRegistrationStatus.idle => 'SIP Idle',
      };
      ref.read(rtcLabTimelineProvider.notifier).record(
        category: RtcLabEventCategory.sip,
        title: title,
        detail: errorMessage,
      );
    };

    ref.onDispose(() {
      _adapter.dispose();
    });

    _initOnStartup();

    return const SipRegistrationState(status: SipRegistrationStatus.idle);
  }

  Future<void> _initOnStartup() async {
    try {
      _currentConfig = await _storage.loadConfig();
      if (_currentConfig.isConfigured) {
        state = state.copyWith(status: SipRegistrationStatus.connecting, extension: _currentConfig.extension);
        await _adapter.register(_currentConfig);
      } else {
        state = state.copyWith(extension: _currentConfig.extension);
      }
    } catch (_) {
      state = state.copyWith(status: SipRegistrationStatus.failed, errorMessage: 'Failed to load configuration');
    }
  }

  Future<SipAccountConfig> loadConfig() async {
    _currentConfig = await _storage.loadConfig();
    return _currentConfig;
  }

  Future<void> saveAndRegister(SipAccountConfig config) async {
    final validationMessage = config.validationMessage;
    if (validationMessage != null) {
      state = state.copyWith(errorMessage: validationMessage);
      return;
    }

    try {
      await _storage.saveConfig(config);
      _currentConfig = config;
      state = SipRegistrationState(status: SipRegistrationStatus.connecting, extension: config.extension);
      await _adapter.register(config);
    } catch (_) {
      state = state.copyWith(status: SipRegistrationStatus.failed, errorMessage: 'Could not save or connect. Check your configuration and try again.');
    }
  }

  Future<void> unregister() async {
    await _adapter.unregister();
    state = state.copyWith(status: SipRegistrationStatus.disconnected);
  }
}

final sipControllerProvider = NotifierProvider<SipController, SipRegistrationState>(SipController.new);

final sipAdapterProvider = Provider<RelaySipAdapter>((ref) => ref.watch(sipControllerProvider.notifier).adapter);
