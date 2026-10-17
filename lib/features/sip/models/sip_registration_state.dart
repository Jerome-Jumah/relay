enum SipRegistrationStatus { idle, connecting, registered, failed, disconnected }

class SipRegistrationState {
  const SipRegistrationState({this.status = SipRegistrationStatus.idle, this.extension = '', this.errorMessage});

  final SipRegistrationStatus status;
  final String extension;
  final String? errorMessage;

  bool get isRegistered => status == SipRegistrationStatus.registered;
  bool get isConnecting => status == SipRegistrationStatus.connecting;

  String get displayLabel {
    return switch (status) {
      SipRegistrationStatus.idle => 'Disconnected',
      SipRegistrationStatus.disconnected => 'Disconnected',
      SipRegistrationStatus.connecting => 'Connecting…',
      SipRegistrationStatus.registered => extension.isNotEmpty ? 'Connected · $extension' : 'Connected',
      SipRegistrationStatus.failed => 'Registration failed',
    };
  }

  String get homeStatusLabel {
    return switch (status) {
      SipRegistrationStatus.idle => 'SIP disconnected',
      SipRegistrationStatus.disconnected => 'SIP disconnected',
      SipRegistrationStatus.connecting => 'SIP connecting…',
      SipRegistrationStatus.registered => extension.isNotEmpty ? 'SIP connected · $extension' : 'SIP connected',
      SipRegistrationStatus.failed => 'SIP registration failed',
    };
  }

  SipRegistrationState copyWith({SipRegistrationStatus? status, String? extension, String? errorMessage}) {
    return SipRegistrationState(
      status: status ?? this.status,
      extension: extension ?? this.extension,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SipRegistrationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          extension == other.extension &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ extension.hashCode ^ errorMessage.hashCode;

  @override
  String toString() => 'SipRegistrationState(status: $status, extension: $extension, errorMessage: $errorMessage)';
}
