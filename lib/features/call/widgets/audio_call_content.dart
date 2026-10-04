import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/call_ui_status.dart';
import 'package:relay/features/call/widgets/call_controls.dart';
import 'package:relay/features/call/widgets/call_focal.dart';
import 'package:relay/features/call/widgets/call_header.dart';
import 'package:relay/shared/widgets/relay_status_pill.dart';

class AudioCallContent extends StatelessWidget {
  const AudioCallContent({
    super.key,
    required this.peer,
    required this.status,
    this.timer = '04:38',
    required this.muted,
    required this.speaker,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onStartVideo,
    required this.onMore,
    required this.onEndCall,
    this.onBack,
  });

  final String peer;
  final CallUiStatus status;
  final String timer;
  final bool muted;
  final bool speaker;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onStartVideo;
  final VoidCallback onMore;
  final VoidCallback onEndCall;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                RelaySpacing.lg,
                RelaySpacing.sm + 4,
                RelaySpacing.lg,
                RelaySpacing.lg,
              ),
              child: Column(
                children: [
                  CallHeader(
                    presentation: CallPresentation.audio,
                    peer: peer,
                    timer: timer,
                    onBack: onBack,
                    onMore: onMore,
                  ),
                  const Spacer(flex: 2),
                  CallFocal(size: constraints.maxHeight < 650 ? 170 : 220),
                  const SizedBox(height: RelaySpacing.lg + 4),
                  Text(
                    peer,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -1,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: RelaySpacing.sm + 4),
                  Text(
                    status == CallUiStatus.connecting ? '00:00' : timer,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: RelaySpacing.sm),
                  RelayStatusPill(
                    status.label,
                    color: status == CallUiStatus.connected ? colors.tertiary : colors.primary,
                  ),
                  if (status == CallUiStatus.reconnecting)
                    Padding(
                      padding: const EdgeInsets.only(top: RelaySpacing.sm),
                      child: Text(
                        'Trying to restore your connection',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.only(top: RelaySpacing.xl),
                    child: CallControls(
                      presentation: CallPresentation.audio,
                      muted: muted,
                      speaker: speaker,
                      onToggleMute: onToggleMute,
                      onToggleSpeaker: onToggleSpeaker,
                      onStartVideo: onStartVideo,
                      onMore: onMore,
                      onEndCall: onEndCall,
                    ),
                  ),
                  const SizedBox(height: RelaySpacing.sm + 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
