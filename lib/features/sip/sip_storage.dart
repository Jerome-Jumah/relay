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

  Future<SipAccountConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final server = prefs.getString(_keyServer) ?? SipAccountConfig.defaultWebSocketUrl;
    final domain = prefs.getString(_keyDomain) ?? SipAccountConfig.defaultDomain;
    final extension = prefs.getString(_keyExtension) ?? '';
    final password = await _secureStorage.read(key: _keyPassword) ?? '';

    return SipAccountConfig(webSocketUrl: server, domain: domain, extension: extension, password: password);
  }

  Future<void> saveConfig(SipAccountConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServer, config.webSocketUrl.trim());
    await prefs.setString(_keyDomain, config.domain.trim());
    await prefs.setString(_keyExtension, config.extension.trim());
    await _secureStorage.write(key: _keyPassword, value: config.password);
  }

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServer);
    await prefs.remove(_keyDomain);
    await prefs.remove(_keyExtension);
    await _secureStorage.delete(key: _keyPassword);
  }
}
