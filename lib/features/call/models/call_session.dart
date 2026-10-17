import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/models/call_lifecycle.dart';

class CallSession {
  const CallSession({
    this.id = '',
    this.peer = '',
    this.direction = CallDirection.outgoing,
    this.lifecycle = CallLifecycle.idle,
    this.initiatedAt,
    this.answeredAt,
    this.endedAt,
    this.failureReason,
  });

  const CallSession.idle()
    : id = '',
      peer = '',
      direction = CallDirection.outgoing,
      lifecycle = CallLifecycle.idle,
      initiatedAt = null,
      answeredAt = null,
      endedAt = null,
      failureReason = null;

  final String id;
  final String peer;
  final CallDirection direction;
  final CallLifecycle lifecycle;
  final DateTime? initiatedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final String? failureReason;

  bool get isActive => lifecycle == CallLifecycle.active;
  bool get isEnded => lifecycle == CallLifecycle.ended || lifecycle == CallLifecycle.failed;
  bool get isConnecting =>
      lifecycle == CallLifecycle.outgoing ||
      lifecycle == CallLifecycle.ringing ||
      lifecycle == CallLifecycle.connecting;

  Duration get duration => answeredAt != null ? (endedAt ?? DateTime.now()).difference(answeredAt!) : Duration.zero;

  String get formattedDuration {
    final d = duration;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  CallUiStatus get uiStatus => switch (lifecycle) {
    CallLifecycle.outgoing => CallUiStatus.calling,
    CallLifecycle.ringing => CallUiStatus.ringing,
    CallLifecycle.connecting => CallUiStatus.connecting,
    CallLifecycle.active => CallUiStatus.connected,
    _ => CallUiStatus.connecting,
  };

  CallSession copyWith({
    String? id,
    String? peer,
    CallDirection? direction,
    CallLifecycle? lifecycle,
    DateTime? initiatedAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    String? failureReason,
  }) {
    return CallSession(
      id: id ?? this.id,
      peer: peer ?? this.peer,
      direction: direction ?? this.direction,
      lifecycle: lifecycle ?? this.lifecycle,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          peer == other.peer &&
          direction == other.direction &&
          lifecycle == other.lifecycle &&
          initiatedAt == other.initiatedAt &&
          answeredAt == other.answeredAt &&
          endedAt == other.endedAt &&
          failureReason == other.failureReason;

  @override
  int get hashCode =>
      id.hashCode ^
      peer.hashCode ^
      direction.hashCode ^
      lifecycle.hashCode ^
      initiatedAt.hashCode ^
      answeredAt.hashCode ^
      endedAt.hashCode ^
      failureReason.hashCode;

  @override
  String toString() =>
      'CallSession(id: $id, peer: $peer, direction: $direction, lifecycle: $lifecycle, duration: $formattedDuration, failureReason: $failureReason)';
}
