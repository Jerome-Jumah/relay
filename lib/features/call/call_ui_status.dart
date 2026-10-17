enum CallUiStatus { calling, ringing, connecting, connected, reconnecting }

extension CallUiStatusLabel on CallUiStatus {
  String get label => switch (this) {
    CallUiStatus.calling => 'Calling…',
    CallUiStatus.ringing => 'Ringing…',
    CallUiStatus.connecting => 'Connecting…',
    CallUiStatus.connected => 'Connected',
    CallUiStatus.reconnecting => 'Reconnecting…',
  };
}
