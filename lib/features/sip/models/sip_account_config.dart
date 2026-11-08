class SipAccountConfig {
  const SipAccountConfig({
    this.webSocketUrl = defaultWebSocketUrl,
    this.domain = defaultDomain,
    this.extension = '',
    this.password = '',
    this.stunUrl = '',
    this.turnUrl = '',
    this.turnUsername = '',
    this.turnPassword = '',
  });

  // No implicit connection to the author's infrastructure.
  static const defaultWebSocketUrl = '';
  static const defaultDomain = '';

  final String webSocketUrl;
  final String domain;
  final String extension;
  final String password;
  final String stunUrl;
  final String turnUrl;
  final String turnUsername;
  final String turnPassword;

  bool get isConfigured =>
      webSocketUrl.trim().isNotEmpty &&
      domain.trim().isNotEmpty &&
      extension.trim().isNotEmpty &&
      password.isNotEmpty;

  String get sipUri => 'sip:${extension.trim()}@${domain.trim()}';

  String get authorizationUser => extension.trim();

  String? get validationMessage {
    final socket = Uri.tryParse(webSocketUrl.trim());
    if (socket == null || socket.scheme != 'wss' || socket.host.isEmpty ||
        socket.userInfo.isNotEmpty || socket.hasFragment) {
      return 'Enter a secure WebSocket URL, including wss://.';
    }
    final sipDomain = domain.trim();
    if (sipDomain.isEmpty || RegExp(r'[\s/@?#]').hasMatch(sipDomain) || sipDomain.contains('://')) {
      return 'Enter the SIP domain separately from the WebSocket URL.';
    }
    if (extension.trim().isEmpty || RegExp(r'[\s@\r\n]').hasMatch(extension.trim()) || password.isEmpty) {
      return 'Enter your extension and SIP password.';
    }
    if (!_validIceUrl(stunUrl.trim(), const ['stun', 'stuns'])) {
      return 'Enter a valid STUN URL or leave it empty.';
    }
    if (!_validIceUrl(turnUrl.trim(), const ['turn', 'turns'])) {
      return 'Enter a valid TURN URL or leave it empty.';
    }
    if (turnUrl.trim().isNotEmpty && (turnUsername.trim().isEmpty || turnPassword.isEmpty)) {
      return 'Enter the TURN username and password for your server.';
    }
    if (turnUrl.trim().isEmpty && (turnUsername.isNotEmpty || turnPassword.isNotEmpty)) {
      return 'Enter a TURN URL or clear the TURN credentials.';
    }
    return null;
  }

  static bool _validIceUrl(String value, List<String> schemes) {
    if (value.isEmpty) return true;
    final separator = value.indexOf(':');
    if (separator < 0) return false;
    final scheme = value.substring(0, separator);
    if (!schemes.contains(scheme)) return false;
    final uri = Uri.tryParse('$scheme://${value.substring(separator + 1)}');
    return uri != null && uri.host.isNotEmpty && uri.userInfo.isEmpty &&
        uri.path.isEmpty && !uri.hasFragment &&
        (!uri.hasQuery || uri.query == 'transport=udp' || uri.query == 'transport=tcp');
  }

  SipAccountConfig copyWith({
    String? webSocketUrl,
    String? domain,
    String? extension,
    String? password,
    String? stunUrl,
    String? turnUrl,
    String? turnUsername,
    String? turnPassword,
  }) => SipAccountConfig(
    webSocketUrl: webSocketUrl ?? this.webSocketUrl,
    domain: domain ?? this.domain,
    extension: extension ?? this.extension,
    password: password ?? this.password,
    stunUrl: stunUrl ?? this.stunUrl,
    turnUrl: turnUrl ?? this.turnUrl,
    turnUsername: turnUsername ?? this.turnUsername,
    turnPassword: turnPassword ?? this.turnPassword,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SipAccountConfig &&
          webSocketUrl == other.webSocketUrl && domain == other.domain &&
          extension == other.extension && password == other.password &&
          stunUrl == other.stunUrl && turnUrl == other.turnUrl &&
          turnUsername == other.turnUsername && turnPassword == other.turnPassword;

  @override
  int get hashCode => Object.hash(
    webSocketUrl, domain, extension, password, stunUrl, turnUrl, turnUsername, turnPassword,
  );

  @override
  String toString() => 'SipAccountConfig([REDACTED])';
}
