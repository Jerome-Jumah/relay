import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:relay/features/call/models/call_state_data.dart';
import 'package:relay/features/call/providers/call_controller.dart';
import 'package:relay/features/rtc_lab/models/rtc_lab_snapshot.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:relay/features/sip/sip_controller.dart';

class RtcLabSamplerNotifier extends Notifier<RtcLabSnapshot> {
  Timer? _timer;
  bool _isSampling = false;

  // Bitrate calculation state
  int? _prevAudioBytesSent;
  int? _prevAudioBytesRecv;
  int? _prevVideoBytesSent;
  int? _prevVideoBytesRecv;
  DateTime? _prevSampleTime;

  @override
  RtcLabSnapshot build() {
    final sipState = ref.watch(sipControllerProvider);
    final callState = ref.watch(callControllerProvider);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    // Provide initial baseline
    return _buildBaselineSnapshot(sipState, callState);
  }

  RtcLabSnapshot _buildBaselineSnapshot(SipRegistrationState sipState, CallStateData callState) {
    final callController = ref.read(callControllerProvider.notifier);

    final regLabel = switch (sipState.status) {
      SipRegistrationStatus.registered => 'Registered (${sipState.extension})',
      SipRegistrationStatus.connecting => 'Connecting…',
      SipRegistrationStatus.failed => 'Failed',
      SipRegistrationStatus.disconnected => 'Disconnected',
      SipRegistrationStatus.idle => 'Idle',
    };

    final transportLabel = switch (sipState.status) {
      SipRegistrationStatus.registered => 'WSS Connected',
      SipRegistrationStatus.connecting => 'Connecting…',
      _ => 'Disconnected',
    };

    if (!callState.session.isActive && !callState.session.isConnecting) {
      return RtcLabSnapshot.idle(registrationState: regLabel, transportState: transportLabel);
    }

    return RtcLabSnapshot(
      timestamp: DateTime.now(),
      registrationState: regLabel,
      transportState: transportLabel,
      peer: callState.session.peer,
      callLifecycle: callState.session.lifecycle.name,
      callDirection: callState.session.direction.name,
      presentation: callState.presentation,
      requestedCallMode: callState.requestedCallMode.name,
      callDuration: callState.session.formattedDuration,
      localVideoSource: callController.localVideoSource,
      localVideoTrackId: callController.currentLocalVideoTrackId,
      isScreenSharing: callController.isScreenSharing,
      previousPresentation: callController.presentationBeforeSharing,
    );
  }

  Future<void> _tick() async {
    if (_isSampling) return;
    _isSampling = true;

    try {
      final snapshot = await _sample();
      state = snapshot;
    } catch (_) {
      // Tolerate sampling error gracefully
    } finally {
      _isSampling = false;
    }
  }

  Future<RtcLabSnapshot> _sample() async {
    final sipState = ref.read(sipControllerProvider);
    final callState = ref.read(callControllerProvider);
    final callController = ref.read(callControllerProvider.notifier);
    final adapter = ref.read(sipAdapterProvider);
    final pc = adapter.peerConnection;

    final regLabel = switch (sipState.status) {
      SipRegistrationStatus.registered => 'Registered (${sipState.extension})',
      SipRegistrationStatus.connecting => 'Connecting…',
      SipRegistrationStatus.failed => 'Failed',
      SipRegistrationStatus.disconnected => 'Disconnected',
      SipRegistrationStatus.idle => 'Idle',
    };

    final transportLabel = switch (sipState.status) {
      SipRegistrationStatus.registered => 'WSS Connected',
      SipRegistrationStatus.connecting => 'Connecting…',
      _ => 'Disconnected',
    };

    final isCallActive = callState.session.isActive;
    final isCallConnecting = callState.session.isConnecting;

    if (pc == null || (!isCallActive && !isCallConnecting)) {
      _prevSampleTime = null;
      return RtcLabSnapshot.idle(registrationState: regLabel, transportState: transportLabel);
    }

    // Inspect WebRTC States
    String? pcState;
    String? iceConnState;
    String? iceGatherState;
    String? signalingState;

    try {
      pcState = pc.connectionState?.name;
      iceConnState = pc.iceConnectionState?.name;
      iceGatherState = pc.iceGatheringState?.name;
      signalingState = pc.signalingState?.name;
    } catch (_) {}

    String? transceiverDir;
    try {
      transceiverDir = await callController.getVideoTransceiverDirection();
    } catch (_) {}

    // Inspect getStats
    List<StatsReport> stats = const [];
    try {
      stats = await pc.getStats();
    } catch (_) {}

    // 1. Build Codec Lookup
    final codecs = <String, String>{};
    for (final r in stats) {
      if (r.type == 'codec') {
        final mime = r.values['mimeType']?.toString() ?? r.values['codec']?.toString();
        if (mime != null) {
          // Normalize e.g. "audio/opus" -> "Opus", "video/VP8" -> "VP8"
          final parts = mime.split('/');
          codecs[r.id] = parts.length > 1 ? parts[1].toUpperCase() : mime;
        }
      }
    }

    // 2. Build Candidates Lookup
    final localCandidates = <String, Map<String, dynamic>>{};
    final remoteCandidates = <String, Map<String, dynamic>>{};
    for (final r in stats) {
      if (r.type == 'local-candidate') {
        localCandidates[r.id] = {
          'type': r.values['candidateType']?.toString(),
          'protocol': r.values['protocol']?.toString().toUpperCase() ?? 'UDP',
          'address': r.values['ip']?.toString() ?? r.values['address']?.toString(),
          'port': r.values['port']?.toString(),
        };
      } else if (r.type == 'remote-candidate') {
        remoteCandidates[r.id] = {
          'type': r.values['candidateType']?.toString(),
          'protocol': r.values['protocol']?.toString().toUpperCase() ?? 'UDP',
          'address': r.values['ip']?.toString() ?? r.values['address']?.toString(),
          'port': r.values['port']?.toString(),
        };
      }
    }

    // 3. Find Active Selected Candidate Pair using strict precedence:
    // A. If transport stats expose selectedCandidatePairId: use that exact candidate-pair report.
    // B. Otherwise prefer: candidate-pair selected == true
    // C. Otherwise: nominated == true AND state == "succeeded"
    // D. Only if none of those exist: report selected pair as unavailable.
    StatsReport? selectedPairReport;

    // A. Check transport stats for selectedCandidatePairId
    String? transportSelectedPairId;
    for (final r in stats) {
      if (r.type == 'transport') {
        final pairId = r.values['selectedCandidatePairId']?.toString();
        if (pairId != null && pairId.isNotEmpty) {
          transportSelectedPairId = pairId;
          break;
        }
      }
    }

    if (transportSelectedPairId != null) {
      for (final r in stats) {
        if (r.type == 'candidate-pair' && r.id == transportSelectedPairId) {
          selectedPairReport = r;
          break;
        }
      }
    }

    // B. Otherwise prefer: candidate-pair selected == true
    if (selectedPairReport == null) {
      for (final r in stats) {
        if (r.type == 'candidate-pair') {
          final isSelected = r.values['selected'] == true || r.values['selected']?.toString().toLowerCase() == 'true';
          if (isSelected) {
            selectedPairReport = r;
            break;
          }
        }
      }
    }

    // C. Otherwise: nominated == true AND state == "succeeded"
    if (selectedPairReport == null) {
      for (final r in stats) {
        if (r.type == 'candidate-pair') {
          final isNominated =
              r.values['nominated'] == true || r.values['nominated']?.toString().toLowerCase() == 'true';
          final stateVal = r.values['state']?.toString().toLowerCase();
          if (isNominated && stateVal == 'succeeded') {
            selectedPairReport = r;
            break;
          }
        }
      }
    }

    // D. Only if one of those was found: extract pair details. Otherwise unavailable.
    bool hasSelectedPair = false;
    String? localCandType;
    String? remoteCandType;
    String? iceProtocol;
    String? localAddr;
    String? remoteAddr;
    double? rttMs;
    int? availableBitrate;

    if (selectedPairReport != null) {
      hasSelectedPair = true;
      final localId = selectedPairReport.values['localCandidateId']?.toString();
      final remoteId = selectedPairReport.values['remoteCandidateId']?.toString();

      final local = localCandidates[localId];
      final remote = remoteCandidates[remoteId];

      localCandType = local?['type'] ?? selectedPairReport.values['localCandidateType']?.toString();
      remoteCandType = remote?['type'] ?? selectedPairReport.values['remoteCandidateType']?.toString();
      iceProtocol =
          local?['protocol'] ??
          remote?['protocol'] ??
          selectedPairReport.values['protocol']?.toString().toUpperCase() ??
          'UDP';

      if (local != null && local['address'] != null) {
        localAddr = '${local['address']}${local['port'] != null ? ':${local['port']}' : ''}';
      }
      if (remote != null && remote['address'] != null) {
        remoteAddr = '${remote['address']}${remote['port'] != null ? ':${remote['port']}' : ''}';
      }

      // RTT normalization by field semantics
      rttMs = _parseCandidatePairRtt(selectedPairReport.values);

      final rawAvail = num.tryParse(selectedPairReport.values['availableOutgoingBitrate']?.toString() ?? '');
      if (rawAvail != null) {
        availableBitrate = rawAvail.toInt();
      }
    }

    // 4. Parse Audio Stats
    String? audioCodec;
    int? audioPacketsSent;
    int? audioPacketsRecv;
    int? audioBytesSent;
    int? audioBytesRecv;
    double? audioJitterMs;
    int? audioPacketsLost;
    double? audioLossPct;
    double? audioRttMs;

    for (final r in stats) {
      final kind = r.values['kind']?.toString() ?? r.values['mediaType']?.toString();
      if (kind == 'audio') {
        if (r.type == 'outbound-rtp') {
          audioPacketsSent = int.tryParse(r.values['packetsSent']?.toString() ?? '');
          audioBytesSent = int.tryParse(r.values['bytesSent']?.toString() ?? '');
          final cId = r.values['codecId']?.toString();
          if (cId != null && codecs.containsKey(cId)) {
            audioCodec = codecs[cId];
          }
        } else if (r.type == 'inbound-rtp') {
          audioPacketsRecv = int.tryParse(r.values['packetsReceived']?.toString() ?? '');
          audioBytesRecv = int.tryParse(r.values['bytesReceived']?.toString() ?? '');
          audioPacketsLost = int.tryParse(r.values['packetsLost']?.toString() ?? '');

          // Jitter normalization by field semantics
          if (r.values.containsKey('jitter')) {
            final rawJitter = num.tryParse(r.values['jitter']?.toString() ?? '');
            if (rawJitter != null) {
              audioJitterMs = rawJitter * 1000.0;
            }
          } else if (r.values.containsKey('googJitterMs')) {
            final rawJitter = num.tryParse(r.values['googJitterMs']?.toString() ?? '');
            if (rawJitter != null) {
              audioJitterMs = rawJitter.toDouble();
            }
          }

          // Audio RTT normalization by field semantics
          if (r.values.containsKey('roundTripTime')) {
            final raw = num.tryParse(r.values['roundTripTime']?.toString() ?? '');
            if (raw != null) {
              audioRttMs = raw * 1000.0;
            }
          } else if (r.values.containsKey('googRtt')) {
            final raw = num.tryParse(r.values['googRtt']?.toString() ?? '');
            if (raw != null) {
              audioRttMs = raw.toDouble();
            }
          } else if (r.values.containsKey('googRttMs')) {
            final raw = num.tryParse(r.values['googRttMs']?.toString() ?? '');
            if (raw != null) {
              audioRttMs = raw.toDouble();
            }
          }

          if (audioPacketsLost != null && audioPacketsRecv != null && (audioPacketsLost + audioPacketsRecv) > 0) {
            audioLossPct = (audioPacketsLost / (audioPacketsLost + audioPacketsRecv)) * 100;
          }

          final cId = r.values['codecId']?.toString();
          if (cId != null && codecs.containsKey(cId)) {
            audioCodec ??= codecs[cId];
          }
        }
      }
    }

    // 5. Parse Video Stats
    String? videoOutCodec;
    String? videoOutResolution;
    int? videoFramesSent;
    int? videoBytesSent;
    String? videoInCodec;
    String? videoInResolution;
    int? videoFramesRecv;
    int? videoBytesRecv;
    int? videoFramesDropped;

    for (final r in stats) {
      final kind = r.values['kind']?.toString() ?? r.values['mediaType']?.toString();
      if (kind == 'video') {
        if (r.type == 'outbound-rtp') {
          final cId = r.values['codecId']?.toString();
          videoOutCodec = codecs[cId] ?? cId;
          final w = r.values['frameWidth'];
          final h = r.values['frameHeight'];
          if (w != null && h != null) {
            videoOutResolution = '$w × $h';
          }
          videoFramesSent = int.tryParse(r.values['framesSent']?.toString() ?? '');
          videoBytesSent = int.tryParse(r.values['bytesSent']?.toString() ?? '');
        } else if (r.type == 'inbound-rtp') {
          final cId = r.values['codecId']?.toString();
          videoInCodec = codecs[cId] ?? cId;
          final w = r.values['frameWidth'];
          final h = r.values['frameHeight'];
          if (w != null && h != null) {
            videoInResolution = '$w × $h';
          }
          videoFramesRecv = int.tryParse(r.values['framesReceived']?.toString() ?? '');
          videoBytesRecv = int.tryParse(r.values['bytesReceived']?.toString() ?? '');
          videoFramesDropped = int.tryParse(r.values['framesDropped']?.toString() ?? '');
        }
      }
    }

    // 6. Calculate Real-Time Bitrate
    final now = DateTime.now();
    double? audioBitrateSent;
    double? audioBitrateRecv;
    double? videoBitrateSent;
    double? videoBitrateRecv;

    if (_prevSampleTime != null) {
      final elapsedSec = now.difference(_prevSampleTime!).inMilliseconds / 1000.0;
      if (elapsedSec >= 0.5) {
        if (_prevAudioBytesSent != null && audioBytesSent != null && audioBytesSent >= _prevAudioBytesSent!) {
          audioBitrateSent = ((audioBytesSent - _prevAudioBytesSent!) * 8) / (elapsedSec * 1000);
        }
        if (_prevAudioBytesRecv != null && audioBytesRecv != null && audioBytesRecv >= _prevAudioBytesRecv!) {
          audioBitrateRecv = ((audioBytesRecv - _prevAudioBytesRecv!) * 8) / (elapsedSec * 1000);
        }
        if (_prevVideoBytesSent != null && videoBytesSent != null && videoBytesSent >= _prevVideoBytesSent!) {
          videoBitrateSent = ((videoBytesSent - _prevVideoBytesSent!) * 8) / (elapsedSec * 1000);
        }
        if (_prevVideoBytesRecv != null && videoBytesRecv != null && videoBytesRecv >= _prevVideoBytesRecv!) {
          videoBitrateRecv = ((videoBytesRecv - _prevVideoBytesRecv!) * 8) / (elapsedSec * 1000);
        }
      }
    }

    _prevAudioBytesSent = audioBytesSent;
    _prevAudioBytesRecv = audioBytesRecv;
    _prevVideoBytesSent = videoBytesSent;
    _prevVideoBytesRecv = videoBytesRecv;
    _prevSampleTime = now;

    return RtcLabSnapshot(
      timestamp: now,
      registrationState: regLabel,
      transportState: transportLabel,
      peer: callState.session.peer,
      callLifecycle: callState.session.lifecycle.name,
      callDirection: callState.session.direction.name,
      presentation: callState.presentation,
      requestedCallMode: callState.requestedCallMode.name,
      callDuration: callState.session.formattedDuration,

      // Peer Connection
      peerConnectionState: pcState,
      iceConnectionState: iceConnState,
      iceGatheringState: iceGatherState,
      signalingState: signalingState,

      // ICE Path
      hasSelectedCandidatePair: hasSelectedPair,
      localCandidateType: localCandType,
      remoteCandidateType: remoteCandType,
      protocol: iceProtocol,
      localAddress: localAddr,
      remoteAddress: remoteAddr,
      roundTripTimeMs: rttMs,
      availableOutgoingBitrate: availableBitrate,

      // Audio
      audioCodec: audioCodec ?? (callState.session.isActive ? 'Opus' : null),
      audioPacketsSent: audioPacketsSent,
      audioPacketsReceived: audioPacketsRecv,
      audioBytesSent: audioBytesSent,
      audioBytesReceived: audioBytesRecv,
      audioBitrateSentKbps: audioBitrateSent,
      audioBitrateReceivedKbps: audioBitrateRecv,
      audioJitterMs: audioJitterMs,
      audioPacketsLost: audioPacketsLost,
      audioPacketLossPercentage: audioLossPct,
      audioRoundTripTimeMs: audioRttMs ?? rttMs,

      // Video
      videoOutboundCodec: videoOutCodec,
      videoOutboundResolution: videoOutResolution,
      videoFramesSent: videoFramesSent,
      videoBytesSent: videoBytesSent,
      videoBitrateSentKbps: videoBitrateSent,
      videoInboundCodec: videoInCodec,
      videoInboundResolution: videoInResolution,
      videoFramesReceived: videoFramesRecv,
      videoBytesReceived: videoBytesRecv,
      videoBitrateReceivedKbps: videoBitrateRecv,
      videoFramesDropped: videoFramesDropped,

      // Local Video Source
      localVideoSource: callController.localVideoSource,
      localVideoTrackId: callController.currentLocalVideoTrackId,
      videoTransceiverDirection: transceiverDir,

      // Screen Share
      isScreenSharing: callController.isScreenSharing,
      previousPresentation: callController.presentationBeforeSharing,
      screenShareTrackId: callController.screenShareStream?.getVideoTracks().firstOrNull?.id,
    );
  }

  static double? _parseCandidatePairRtt(Map<dynamic, dynamic> values) {
    // 1. currentRoundTripTime: W3C standard candidate-pair RTT in seconds -> multiply by 1000
    if (values.containsKey('currentRoundTripTime')) {
      final raw = num.tryParse(values['currentRoundTripTime']?.toString() ?? '');
      if (raw != null) {
        return raw * 1000.0;
      }
    }

    // 2. roundTripTime: W3C standard RTT in seconds -> multiply by 1000
    if (values.containsKey('roundTripTime')) {
      final raw = num.tryParse(values['roundTripTime']?.toString() ?? '');
      if (raw != null) {
        return raw * 1000.0;
      }
    }

    // 3. googRtt / googRttMs: Legacy libwebrtc stats -> already in milliseconds
    if (values.containsKey('googRtt')) {
      final raw = num.tryParse(values['googRtt']?.toString() ?? '');
      if (raw != null) {
        return raw.toDouble();
      }
    }
    if (values.containsKey('googRttMs')) {
      final raw = num.tryParse(values['googRttMs']?.toString() ?? '');
      if (raw != null) {
        return raw.toDouble();
      }
    }

    // If source field is unknown or ambiguous, return null rather than presenting an incorrect RTT
    return null;
  }
}

final rtcLabSamplerProvider = NotifierProvider<RtcLabSamplerNotifier, RtcLabSnapshot>(RtcLabSamplerNotifier.new);
