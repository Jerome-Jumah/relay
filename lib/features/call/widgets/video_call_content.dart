import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/features/call/widgets/mock_video_surface.dart';

class VideoCallContent extends StatelessWidget {
  const VideoCallContent({
    super.key,
    this.remoteRenderer,
    this.hasRemoteVideo = false,
    required this.onToggleControls,
    this.camera = true,
    this.flipped = false,
    this.onToggleFlip,
    this.fallback,
  });

  final RTCVideoRenderer? remoteRenderer;
  final bool hasRemoteVideo;
  final VoidCallback onToggleControls;
  final bool camera;
  final bool flipped;
  final VoidCallback? onToggleFlip;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final hasStream = remoteRenderer != null && remoteRenderer!.srcObject != null;

    return GestureDetector(
      onTap: onToggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasStream)
            ColoredBox(
              color: Colors.black,
              child: RTCVideoView(remoteRenderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          if (!hasRemoteVideo)
            Positioned.fill(
              child: fallback ?? const MockVideoSurface(cameraOff: true),
            ),
        ],
      ),
    );
  }
}
