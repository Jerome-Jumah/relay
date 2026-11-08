import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SipStorage {
  const SipStorage({this._secureStorage = const FlutterSecureStorage()});

  final FlutterSecureStorage _secureStorage;

  static const _keyServer = 'relay_sip_server';
  static const _keyDomain = 'relay_sip_domain';
  static const _keyExtension = 'relay_sip_extension';
  static const _keyPassword = 'relay_sip_password';
  static const _keyStunUrl = 'relay_stun_url';
  static const _keyTurnUrl = 'relay_turn_url';
  static const _keyTurnUsername = 'relay_turn_username';
  static const _keyTurnPassword = 'relay_turn_password';

  Future<SipAccountConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString(_keyServer) ?? SipAccountConfig.defaultWebSocketUrl;
    final domain = prefs.getString(_keyDomain) ?? SipAccountConfig.defaultDomain;
    final extension = prefs.getString(_keyExtension) ?? '';
    final password = await _secureStorage.read(key: _keyPassword) ?? '';

    return SipAccountConfig(
      webSocketUrl: server,
      domain: domain,
      extension: extension,
      password: password,
      stunUrl: prefs.getString(_keyStunUrl) ?? '',
      turnUrl: prefs.getString(_keyTurnUrl) ?? '',
      turnUsername: await _secureStorage.read(key: _keyTurnUsername) ?? '',
      turnPassword: await _secureStorage.read(key: _keyTurnPassword) ?? '',
    );
  }

  Future<void> saveConfig(SipAccountConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServer, config.webSocketUrl.trim());
    await prefs.setString(_keyDomain, config.domain.trim());
    await prefs.setString(_keyExtension, config.extension.trim());
    await _secureStorage.write(key: _keyPassword, value: config.password);
    await prefs.setString(_keyStunUrl, config.stunUrl.trim());
    await prefs.setString(_keyTurnUrl, config.turnUrl.trim());
    await _secureStorage.write(key: _keyTurnUsername, value: config.turnUsername.trim());
    await _secureStorage.write(key: _keyTurnPassword, value: config.turnPassword);
  }

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServer);
    await prefs.remove(_keyDomain);
    await prefs.remove(_keyExtension);
    await _secureStorage.delete(key: _keyPassword);
    await prefs.remove(_keyStunUrl);
    await prefs.remove(_keyTurnUrl);
    await _secureStorage.delete(key: _keyTurnUsername);
    await _secureStorage.delete(key: _keyTurnPassword);
  }
}
