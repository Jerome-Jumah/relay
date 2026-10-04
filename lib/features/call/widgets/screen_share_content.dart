import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/call_presentation.dart';
import 'package:relay/features/call/widgets/call_controls.dart';
import 'package:relay/features/call/widgets/call_header.dart';
import 'package:relay/features/call/widgets/local_video_preview.dart';
import 'package:relay/features/call/widgets/mock_code_editor.dart';

class ScreenShareContent extends StatelessWidget {
  const ScreenShareContent({
    super.key,
    required this.peer,
    this.timer = '05:12',
    required this.muted,
    this.camera = true,
    required this.onToggleMute,
    required this.onStopScreenShare,
    required this.onMore,
    required this.onEndCall,
    this.onBack,
  });

  final String peer;
  final String timer;
  final bool muted;
  final bool camera;
  final VoidCallback onToggleMute;
  final VoidCallback onStopScreenShare;
  final VoidCallback onMore;
  final VoidCallback onEndCall;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: SizedBox(
        height: constraints.maxHeight.clamp(
          560 + (MediaQuery.textScalerOf(context).scale(14) / 14 - 1) * 440,
          double.infinity,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RelaySpacing.sm + 2,
                RelaySpacing.sm + 2,
                RelaySpacing.sm + 2,
                RelaySpacing.sm + 6,
              ),
              child: CallHeader(
                presentation: CallPresentation.screenShare,
                peer: peer,
                timer: timer,
                onBack: onBack,
                onMore: onMore,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: MockCodeEditor()),
                  Positioned(
                    right: RelaySpacing.md,
                    bottom: 48,
                    child: LocalVideoPreview(
                      width: 82,
                      height: 108,
                      cameraOff: !camera,
                    ),
                  ),
                ],
              ),
            ),
            CallControls(
              presentation: CallPresentation.screenShare,
              muted: muted,
              onToggleMute: onToggleMute,
              onStopScreenShare: onStopScreenShare,
              onMore: onMore,
              onEndCall: onEndCall,
            ),
          ],
        ),
      ),
    ),
  );
}
