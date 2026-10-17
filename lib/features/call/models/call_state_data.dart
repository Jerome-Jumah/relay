import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/models/call_session.dart';

class CallStateData {
  const CallStateData({
    this.session = const CallSession.idle(),
    this.isMuted = false,
    this.isSpeaker = false,
    this.presentation = CallPresentation.audio,
    this.localVideoTrackPresent = false,
    this.remoteVideoTrackPresent = false,
    this.isCameraEnabled = true,
    this.isFrontCamera = true,
  });

  final CallSession session;
  final bool isMuted;
  final bool isSpeaker;
  final CallPresentation presentation;
  final bool localVideoTrackPresent;
  final bool remoteVideoTrackPresent;
  final bool isCameraEnabled;
  final bool isFrontCamera;

  CallStateData copyWith({
    CallSession? session,
    bool? isMuted,
    bool? isSpeaker,
    CallPresentation? presentation,
    bool? localVideoTrackPresent,
    bool? remoteVideoTrackPresent,
    bool? isCameraEnabled,
    bool? isFrontCamera,
  }) {
    return CallStateData(
      session: session ?? this.session,
      isMuted: isMuted ?? this.isMuted,
      isSpeaker: isSpeaker ?? this.isSpeaker,
      presentation: presentation ?? this.presentation,
      localVideoTrackPresent: localVideoTrackPresent ?? this.localVideoTrackPresent,
      remoteVideoTrackPresent: remoteVideoTrackPresent ?? this.remoteVideoTrackPresent,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallStateData &&
          runtimeType == other.runtimeType &&
          session == other.session &&
          isMuted == other.isMuted &&
          isSpeaker == other.isSpeaker &&
          presentation == other.presentation &&
          localVideoTrackPresent == other.localVideoTrackPresent &&
          remoteVideoTrackPresent == other.remoteVideoTrackPresent &&
          isCameraEnabled == other.isCameraEnabled &&
          isFrontCamera == other.isFrontCamera;

  @override
  int get hashCode =>
      session.hashCode ^
      isMuted.hashCode ^
      isSpeaker.hashCode ^
      presentation.hashCode ^
      localVideoTrackPresent.hashCode ^
      remoteVideoTrackPresent.hashCode ^
      isCameraEnabled.hashCode ^
      isFrontCamera.hashCode;

  @override
  String toString() =>
      'CallStateData(session: $session, isMuted: $isMuted, isSpeaker: $isSpeaker, presentation: $presentation, localVideoTrackPresent: $localVideoTrackPresent, remoteVideoTrackPresent: $remoteVideoTrackPresent, isCameraEnabled: $isCameraEnabled, isFrontCamera: $isFrontCamera)';
}
