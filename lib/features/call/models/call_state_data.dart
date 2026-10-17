import 'package:relay/features/call/models/call_session.dart';

class CallStateData {
  const CallStateData({this.session = const CallSession.idle(), this.isMuted = false, this.isSpeaker = false});

  final CallSession session;
  final bool isMuted;
  final bool isSpeaker;

  CallStateData copyWith({CallSession? session, bool? isMuted, bool? isSpeaker}) {
    return CallStateData(
      session: session ?? this.session,
      isMuted: isMuted ?? this.isMuted,
      isSpeaker: isSpeaker ?? this.isSpeaker,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallStateData &&
          runtimeType == other.runtimeType &&
          session == other.session &&
          isMuted == other.isMuted &&
          isSpeaker == other.isSpeaker;

  @override
  int get hashCode => session.hashCode ^ isMuted.hashCode ^ isSpeaker.hashCode;

  @override
  String toString() => 'CallStateData(session: $session, isMuted: $isMuted, isSpeaker: $isSpeaker)';
}
