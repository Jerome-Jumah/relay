enum CallUiStatus { connecting, connected, reconnecting }

extension CallUiStatusLabel on CallUiStatus {
  String get label => switch (this) {
    CallUiStatus.connecting => 'Connecting…',
    CallUiStatus.connected => 'Connected',
    CallUiStatus.reconnecting => 'Reconnecting…',
  };
}
