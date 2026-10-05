import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/features/call/call_presentation.dart';

abstract final class CallMoreSheet {
  static void show(
    BuildContext context, {
    CallPresentation? presentation,
    VoidCallback? onStartScreenShare,
    VoidCallback? onStopScreenShare,
    VoidCallback? onSwitchToAudio,
    VoidCallback? onSwitchToVideo,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (presentation == CallPresentation.audio && onSwitchToVideo != null)
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Switch to video'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onSwitchToVideo();
                },
              ),
            if (presentation == CallPresentation.video && onSwitchToAudio != null)
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Switch to audio'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onSwitchToAudio();
                },
              ),
            if (presentation != CallPresentation.screenShare && onStartScreenShare != null)
              ListTile(
                leading: const Icon(Icons.screen_share_outlined),
                title: const Text('Share screen'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onStartScreenShare();
                },
              ),
            if (presentation == CallPresentation.screenShare && onStopScreenShare != null)
              ListTile(
                leading: const Icon(Icons.stop_screen_share_outlined),
                title: const Text('Stop sharing'),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(sheetContext);
                  onStopScreenShare();
                },
              ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('RTC Lab'),
              subtitle: const Text('See the mock connection details'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/rtc-lab');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Call settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    ),
  );
}
