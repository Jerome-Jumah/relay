import 'package:cue/cue.dart';
import 'package:material_ui/material_ui.dart';

import 'package:relay/features/call/widgets/mock_video_surface.dart';

class VideoCallContent extends StatelessWidget {
  const VideoCallContent({
    super.key,
    required this.onToggleControls,
    this.camera = true,
    this.flipped = false,
    this.onToggleFlip,
  });

  final VoidCallback onToggleControls;
  final bool camera;
  final bool flipped;
  final VoidCallback? onToggleFlip;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Actor(
      acts: [
        .fadeIn(),
        if (!reducedMotion) .scale(from: 0.98),
      ],
      child: GestureDetector(
        onTap: onToggleControls,
        child: const MockVideoSurface(),
      ),
    );
  }
}
