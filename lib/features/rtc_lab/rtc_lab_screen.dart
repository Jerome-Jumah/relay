import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/rtc_lab/models/rtc_lab_event.dart';
import 'package:relay/features/rtc_lab/models/rtc_lab_snapshot.dart';
import 'package:relay/features/rtc_lab/providers/rtc_lab_sampler.dart';
import 'package:relay/features/rtc_lab/providers/rtc_lab_timeline.dart';
import 'package:relay/features/rtc_lab/widgets/diagnostic_section.dart';
import 'package:relay/features/rtc_lab/widgets/ice_path.dart';
import 'package:relay/shared/widgets/relay_section.dart';
import 'package:relay/shared/widgets/relay_settings_tile.dart';

class RtcLabScreen extends ConsumerStatefulWidget {
  const RtcLabScreen({super.key, this.detailed = false});

  final bool detailed;

  @override
  ConsumerState<RtcLabScreen> createState() => _RtcLabScreenState();
}

class _RtcLabScreenState extends ConsumerState<RtcLabScreen> {
  late bool detailed = widget.detailed;
  bool forceTurn = false;
  bool overlay = false;
  bool verbose = false;

  @override
  void didUpdateWidget(RtcLabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detailed != widget.detailed) {
      detailed = widget.detailed;
    }
  }

  Future<void> copyDiagnostics(RtcLabSnapshot snapshot) async {
    final buffer = StringBuffer();
    buffer.writeln('Relay RTC Diagnostics · ${snapshot.timestamp.toIso8601String()}');
    buffer.writeln('SIP: ${snapshot.registrationState} · ${snapshot.transportState}');
    buffer.writeln('Call: ${snapshot.callLifecycle} · Peer: ${snapshot.peer ?? "none"} · Mode: ${snapshot.presentation.name} · Duration: ${snapshot.callDuration ?? "00:00"}');
    buffer.writeln('WebRTC: PC=${snapshot.peerConnectionState ?? "n/a"} · ICE=${snapshot.iceConnectionState ?? "n/a"} · Signaling=${snapshot.signalingState ?? "n/a"}');
    if (snapshot.hasSelectedCandidatePair) {
      buffer.writeln('Path: ${snapshot.localCandidateType} (${snapshot.localAddress}) → ${snapshot.remoteCandidateType} (${snapshot.remoteAddress}) · ${snapshot.protocol} · RTT: ${snapshot.roundTripTimeMs?.round() ?? "n/a"} ms · TURN selected: ${snapshot.isTurnSelected}');
    } else {
      buffer.writeln('Path: No candidate pair selected');
    }
    buffer.writeln('Audio: ${snapshot.audioCodec ?? "n/a"} · Send: ${RtcLabSnapshot.formatBitrate(snapshot.audioBitrateSentKbps)} · Recv: ${RtcLabSnapshot.formatBitrate(snapshot.audioBitrateReceivedKbps)} · Jitter: ${snapshot.audioJitterMs?.toStringAsFixed(1) ?? "n/a"} ms · Loss: ${snapshot.audioPacketLossPercentage?.toStringAsFixed(1) ?? "n/a"}%');
    buffer.writeln('Video: Source=${snapshot.localVideoSource} · Track=${snapshot.localVideoTrackId ?? "none"} · Direction=${snapshot.videoTransceiverDirection ?? "n/a"}');
    if (snapshot.videoOutboundCodec != null || snapshot.videoInboundCodec != null) {
      buffer.writeln('Video Out: ${snapshot.videoOutboundCodec ?? "n/a"} · ${snapshot.videoOutboundResolution ?? "n/a"} · ${RtcLabSnapshot.formatBitrate(snapshot.videoBitrateSentKbps)} · Frames: ${snapshot.videoFramesSent ?? "n/a"}');
      buffer.writeln('Video In: ${snapshot.videoInboundCodec ?? "n/a"} · ${snapshot.videoInboundResolution ?? "n/a"} · ${RtcLabSnapshot.formatBitrate(snapshot.videoBitrateReceivedKbps)} · Frames: ${snapshot.videoFramesReceived ?? "n/a"}');
    }

    final events = ref.read(rtcLabTimelineProvider);
    if (events.isNotEmpty) {
      buffer.writeln('\nRecent Events:');
      for (final e in events.take(8)) {
        buffer.writeln('  [${e.formattedTime}] [${e.categoryLabel}] ${e.title}${e.detail != null ? " (${e.detail})" : ""}');
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnostics copied to clipboard'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final snapshot = ref.watch(rtcLabSamplerProvider);
    final events = ref.watch(rtcLabTimelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RTC Lab', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RelaySpacing.lg - 2,
            RelaySpacing.sm,
            RelaySpacing.lg - 2,
            RelaySpacing.lg + 4,
          ),
          children: [
            Text(
              "What's happening underneath the call",
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: RelaySpacing.lg),

            // Call / Idle Banner
            _buildStatusBanner(context, snapshot),
            const SizedBox(height: RelaySpacing.lg + 4),

            // 1. Session Section
            DiagnosticSection(
              title: 'Session',
              values: {
                'SIP registration': snapshot.registrationState,
                'Signaling transport': snapshot.transportState,
                'Call state': snapshot.isCallActive
                    ? 'Active (${snapshot.callDirection ?? "call"})'
                    : 'Idle (no active call)',
                'Peer': snapshot.peer ?? '—',
                'Call mode': snapshot.isCallActive
                    ? (snapshot.isScreenSharing ? 'Screen share' : snapshot.presentation.name)
                    : '—',
                'Duration': snapshot.callDuration ?? '—',
              },
            ),

            // 2. Connection Section
            DiagnosticSection(
              title: 'Connection',
              values: {
                'PeerConnection': snapshot.peerConnectionState ?? (snapshot.isCallActive ? 'Connected' : '—'),
                'ICE connection': snapshot.iceConnectionState ?? (snapshot.isCallActive ? 'Connected' : '—'),
                'ICE gathering': snapshot.iceGatheringState ?? '—',
                'Signaling state': snapshot.signalingState ?? '—',
              },
            ),

            // 3. ICE Path Card & Detailed Candidate Pair
            IcePath(snapshot: snapshot),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => detailed = !detailed),
                icon: Icon(detailed ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                label: Text(detailed ? 'Less detail' : 'Connection details'),
              ),
            ),
            if (detailed) ...[
              DiagnosticSection(
                title: 'Selected candidate pair',
                values: {
                  'Path type': snapshot.hasSelectedCandidatePair
                      ? (snapshot.isTurnSelected ? 'Relayed (TURN)' : 'Direct peer-to-peer')
                      : '—',
                  'Local candidate': snapshot.localCandidateType != null
                      ? '${snapshot.localCandidateType} (${snapshot.protocol ?? "UDP"})'
                      : '—',
                  'Local address': snapshot.localAddress ?? '—',
                  'Remote candidate': snapshot.remoteCandidateType != null
                      ? '${snapshot.remoteCandidateType} (${snapshot.protocol ?? "UDP"})'
                      : '—',
                  'Remote address': snapshot.remoteAddress ?? '—',
                  'Protocol': snapshot.protocol ?? '—',
                  'Round trip time (RTT)': snapshot.roundTripTimeMs != null
                      ? '${snapshot.roundTripTimeMs!.round()} ms'
                      : '—',
                  'Available bitrate': snapshot.availableOutgoingBitrate != null
                      ? RtcLabSnapshot.formatBitrate(snapshot.availableOutgoingBitrate! / 1000)
                      : '—',
                },
              ),
              const SizedBox(height: RelaySpacing.sm + 4),
            ],

            // 4. Audio Section
            DiagnosticSection(
              title: 'Audio',
              values: {
                'Codec': snapshot.audioCodec ?? (snapshot.isCallActive ? 'Opus' : '—'),
                'Send bitrate': RtcLabSnapshot.formatBitrate(snapshot.audioBitrateSentKbps),
                'Receive bitrate': RtcLabSnapshot.formatBitrate(snapshot.audioBitrateReceivedKbps),
                'Jitter': snapshot.audioJitterMs != null
                    ? '${snapshot.audioJitterMs!.toStringAsFixed(1)} ms'
                    : '—',
                'Packet loss': snapshot.audioPacketLossPercentage != null
                    ? '${snapshot.audioPacketLossPercentage!.toStringAsFixed(1)}%'
                    : (snapshot.audioPacketsLost != null ? '${snapshot.audioPacketsLost} pkts' : '—'),
                'Packets (sent / recv)': (snapshot.audioPacketsSent != null || snapshot.audioPacketsReceived != null)
                    ? '${snapshot.audioPacketsSent ?? "—"} / ${snapshot.audioPacketsReceived ?? "—"}'
                    : '—',
                'Audio RTT': snapshot.audioRoundTripTimeMs != null
                    ? '${snapshot.audioRoundTripTimeMs!.round()} ms'
                    : '—',
              },
            ),

            // 5. Video Section
            DiagnosticSection(
              title: 'Video & Screen Sharing',
              values: {
                'Local video source': switch (snapshot.localVideoSource) {
                  'display' => 'Display (screen capture)',
                  'camera' => 'Camera',
                  _ => snapshot.isCallActive ? 'None (dormant video m-line)' : '—',
                },
                'Transceiver direction': snapshot.videoTransceiverDirection ?? '—',
                'Local track ID': snapshot.shortLocalVideoTrackId,
                'Outbound codec': snapshot.videoOutboundCodec ?? '—',
                'Outbound resolution': snapshot.videoOutboundResolution ?? '—',
                'Send bitrate': RtcLabSnapshot.formatBitrate(snapshot.videoBitrateSentKbps),
                'Frames sent': snapshot.videoFramesSent != null ? '${snapshot.videoFramesSent}' : '—',
                'Inbound codec': snapshot.videoInboundCodec ?? '—',
                'Inbound resolution': snapshot.videoInboundResolution ?? '—',
                'Receive bitrate': RtcLabSnapshot.formatBitrate(snapshot.videoBitrateReceivedKbps),
                'Frames received': snapshot.videoFramesReceived != null ? '${snapshot.videoFramesReceived}' : '—',
                if (snapshot.videoFramesDropped != null)
                  'Frames dropped': '${snapshot.videoFramesDropped}',
              },
            ),

            // 6. Experiments & Actions
            RelaySection(
              title: 'Experiments & Actions',
              children: [
                RelaySettingsTile(
                  icon: Icons.alt_route_rounded,
                  title: 'Force TURN',
                  trailing: Switch(
                    value: forceTurn,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => forceTurn = value);
                    },
                  ),
                ),
                RelaySettingsTile(
                  icon: Icons.insights_outlined,
                  title: 'Show stats overlay',
                  trailing: Switch(
                    value: overlay,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => overlay = value);
                    },
                  ),
                ),
                RelaySettingsTile(
                  icon: Icons.list_alt_rounded,
                  title: 'Verbose RTC events',
                  trailing: Switch(
                    value: verbose,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      setState(() => verbose = value);
                    },
                  ),
                ),
                RelaySettingsTile(
                  icon: Icons.copy_outlined,
                  title: 'Copy real diagnostics',
                  divider: false,
                  onTap: () => copyDiagnostics(snapshot),
                ),
              ],
            ),
            if (forceTurn || overlay || verbose)
              Padding(
                padding: const EdgeInsets.only(left: RelaySpacing.sm + 4, bottom: RelaySpacing.lg),
                child: Text(
                  'Experiment switches are preview controls.\nLive call metrics reflect real WebRTC statistics.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: colors.onSurfaceVariant),
                ),
              ),

            // 7. Real Event Timeline
            _buildTimelineSection(context, events),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, RtcLabSnapshot snapshot) {
    final colors = Theme.of(context).colorScheme;

    if (snapshot.isCallActive) {
      final isSharing = snapshot.isScreenSharing;
      final isVideo = snapshot.presentation == CallPresentation.video && !isSharing;
      final modeIcon = isSharing
          ? Icons.screen_share_rounded
          : (isVideo ? Icons.videocam_rounded : Icons.call_rounded);

      return Container(
        padding: const EdgeInsets.all(RelaySpacing.md + 4),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          borderRadius: BorderRadius.circular(RelayRadius.lg - 2),
        ),
        child: Row(
          children: [
            Icon(modeIcon, color: colors.tertiary, size: 28),
            const SizedBox(width: RelaySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Call Active',
                        style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: RelaySpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(RelayRadius.sm),
                        ),
                        child: Text(
                          snapshot.callDuration ?? '00:00',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Peer: ${snapshot.peer ?? "unknown"} · ${snapshot.isScreenSharing ? "Sharing screen" : snapshot.presentation.name}',
                    style: TextStyle(color: colors.onTertiaryContainer.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Idle State Banner
    return Container(
      padding: const EdgeInsets.all(RelaySpacing.md + 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RelayRadius.lg - 2),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.primary, size: 24),
          const SizedBox(width: RelaySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Active Call',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start a call to inspect ICE candidate negotiation, codecs, real-time bitrates, and live media diagnostics.',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(BuildContext context, List<RtcLabEvent> events) {
    final colors = Theme.of(context).colorScheme;

    return RelaySection(
      title: 'Event Timeline',
      children: [
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.md + 2, vertical: RelaySpacing.md),
            child: Text(
              'No events recorded yet. Connect a call or toggle media to see real-time signaling and RTC events.',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          )
        else
          for (final entry in events)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.md + 2, vertical: RelaySpacing.sm + 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.formattedTime,
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: RelaySpacing.sm + 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: entry.getCategoryColor(colors).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(RelayRadius.sm),
                    ),
                    child: Text(
                      entry.categoryLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: entry.getCategoryColor(colors),
                      ),
                    ),
                  ),
                  const SizedBox(width: RelaySpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.onSurface),
                        ),
                        if (entry.detail != null && entry.detail!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              entry.detail!,
                              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
