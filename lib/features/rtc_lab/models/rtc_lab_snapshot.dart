import 'package:relay/features/call/call_presentation.dart';

class RtcLabSnapshot {
  const RtcLabSnapshot({
    required this.timestamp,

    // SIGNALING
    this.registrationState = 'Unregistered',
    this.transportState = 'Disconnected',
    this.peer,
    this.callLifecycle = 'idle',
    this.callDirection,
    this.presentation = CallPresentation.audio,
    this.requestedCallMode,
    this.callDuration,

    // PEER CONNECTION
    this.peerConnectionState,
    this.iceConnectionState,
    this.iceGatheringState,
    this.signalingState,

    // ICE PATH
    this.hasSelectedCandidatePair = false,
    this.localCandidateType,
    this.remoteCandidateType,
    this.protocol,
    this.localAddress,
    this.remoteAddress,
    this.roundTripTimeMs,
    this.availableOutgoingBitrate,

    // AUDIO
    this.audioCodec,
    this.audioPacketsSent,
    this.audioPacketsReceived,
    this.audioBytesSent,
    this.audioBytesReceived,
    this.audioBitrateSentKbps,
    this.audioBitrateReceivedKbps,
    this.audioJitterMs,
    this.audioPacketsLost,
    this.audioPacketLossPercentage,
    this.audioRoundTripTimeMs,

    // VIDEO
    this.videoOutboundCodec,
    this.videoOutboundResolution,
    this.videoFramesSent,
    this.videoBytesSent,
    this.videoBitrateSentKbps,
    this.videoInboundCodec,
    this.videoInboundResolution,
    this.videoFramesReceived,
    this.videoBytesReceived,
    this.videoBitrateReceivedKbps,
    this.videoFramesDropped,

    // LOCAL VIDEO SOURCE
    this.localVideoSource = 'none',
    this.localVideoTrackId,
    this.videoTransceiverDirection,

    // SCREEN SHARE
    this.isScreenSharing = false,
    this.previousPresentation,
    this.screenShareTrackId,
  });

  factory RtcLabSnapshot.idle({String registrationState = 'Unregistered', String transportState = 'Disconnected'}) {
    return RtcLabSnapshot(
      timestamp: DateTime.now(),
      registrationState: registrationState,
      transportState: transportState,
      callLifecycle: 'idle',
      presentation: CallPresentation.audio,
      localVideoSource: 'none',
      isScreenSharing: false,
    );
  }

  final DateTime timestamp;

  // Signaling
  final String registrationState;
  final String transportState;
  final String? peer;
  final String callLifecycle;
  final String? callDirection;
  final CallPresentation presentation;
  final String? requestedCallMode;
  final String? callDuration;

  // Peer Connection
  final String? peerConnectionState;
  final String? iceConnectionState;
  final String? iceGatheringState;
  final String? signalingState;

  // ICE Path
  final bool hasSelectedCandidatePair;
  final String? localCandidateType;
  final String? remoteCandidateType;
  final String? protocol;
  final String? localAddress;
  final String? remoteAddress;
  final double? roundTripTimeMs;
  final int? availableOutgoingBitrate;

  // Media - Audio
  final String? audioCodec;
  final int? audioPacketsSent;
  final int? audioPacketsReceived;
  final int? audioBytesSent;
  final int? audioBytesReceived;
  final double? audioBitrateSentKbps;
  final double? audioBitrateReceivedKbps;
  final double? audioJitterMs;
  final int? audioPacketsLost;
  final double? audioPacketLossPercentage;
  final double? audioRoundTripTimeMs;

  // Media - Video
  final String? videoOutboundCodec;
  final String? videoOutboundResolution;
  final int? videoFramesSent;
  final int? videoBytesSent;
  final double? videoBitrateSentKbps;
  final String? videoInboundCodec;
  final String? videoInboundResolution;
  final int? videoFramesReceived;
  final int? videoBytesReceived;
  final double? videoBitrateReceivedKbps;
  final int? videoFramesDropped;

  // Local Video Source
  final String localVideoSource;
  final String? localVideoTrackId;
  final String? videoTransceiverDirection;

  // Screen Share
  final bool isScreenSharing;
  final CallPresentation? previousPresentation;
  final String? screenShareTrackId;

  bool get isCallActive => callLifecycle == 'active';
  bool get isTurnSelected =>
      (localCandidateType != null && localCandidateType!.toLowerCase() == 'relay') ||
      (remoteCandidateType != null && remoteCandidateType!.toLowerCase() == 'relay');

  String get shortLocalVideoTrackId {
    if (localVideoTrackId == null) return '—';
    if (localVideoTrackId!.length > 8) {
      return '${localVideoTrackId!.substring(0, 8)}…';
    }
    return localVideoTrackId!;
  }

  String get shortScreenShareTrackId {
    if (screenShareTrackId == null) return '—';
    if (screenShareTrackId!.length > 8) {
      return '${screenShareTrackId!.substring(0, 8)}…';
    }
    return screenShareTrackId!;
  }

  static String formatBitrate(double? kbps) {
    if (kbps == null) return '—';
    if (kbps >= 1000) {
      return '${(kbps / 1000).toStringAsFixed(1)} Mbps';
    }
    return '${kbps.round()} kbps';
  }
}
