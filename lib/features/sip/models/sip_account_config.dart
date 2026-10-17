class SipAccountConfig {
  const SipAccountConfig({
    this.webSocketUrl = defaultWebSocketUrl,
    this.domain = defaultDomain,
    this.extension = '',
    this.password = '',
  });

  static const defaultWebSocketUrl = 'wss://sip.code4flare.com';
  static const defaultDomain = 'sip.code4flare.com';

  final String webSocketUrl;
  final String domain;
  final String extension;
  final String password;

  bool get isConfigured =>
      webSocketUrl.trim().isNotEmpty &&
      domain.trim().isNotEmpty &&
      extension.trim().isNotEmpty &&
      password.trim().isNotEmpty;

  String get sipUri => 'sip:${extension.trim()}@${domain.trim()}';

  String get authorizationUser => extension.trim();

  SipAccountConfig copyWith({String? webSocketUrl, String? domain, String? extension, String? password}) {
    return SipAccountConfig(
      webSocketUrl: webSocketUrl ?? this.webSocketUrl,
      domain: domain ?? this.domain,
      extension: extension ?? this.extension,
      password: password ?? this.password,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SipAccountConfig &&
          runtimeType == other.runtimeType &&
          webSocketUrl == other.webSocketUrl &&
          domain == other.domain &&
          extension == other.extension &&
          password == other.password;

  @override
  int get hashCode => webSocketUrl.hashCode ^ domain.hashCode ^ extension.hashCode ^ password.hashCode;

  @override
  String toString() =>
      'SipAccountConfig(webSocketUrl: $webSocketUrl, domain: $domain, extension: $extension, password: [REDACTED])';
}
