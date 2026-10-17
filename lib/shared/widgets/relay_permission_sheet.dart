import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/shared/permissions/relay_permissions.dart';

abstract final class RelayPermissionSheet {
  /// Contextual permission prompt for microphone.
  /// Returns `true` if granted, `false` otherwise.
  static Future<bool> ensureMicrophone(BuildContext context, RelayPermissions permissions) async {
    final status = await permissions.microphoneStatus();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!context.mounted) return false;
      await _showSettingsRationale(
        context,
        icon: Icons.mic_off_rounded,
        title: 'Microphone access disabled',
        body: 'Microphone access is disabled in system settings. Relay requires microphone access to send audio during calls.',
        onOpenSettings: permissions.openSettings,
      );
      return false;
    }

    if (!context.mounted) return false;
    final proceed = await _showRequestRationale(
      context,
      icon: Icons.mic_rounded,
      title: 'Allow microphone access?',
      body: 'Relay uses your microphone to send audio during calls. Microphone access is only used while a call needs it.',
      continueLabel: 'Continue',
      cancelLabel: 'Not now',
    );

    if (!proceed) {
      return false;
    }

    final result = await permissions.requestMicrophone();
    return result.isGranted;
  }

  /// Contextual permission prompt for camera.
  /// Returns `true` if granted, `false` otherwise.
  static Future<bool> ensureCamera(BuildContext context, RelayPermissions permissions) async {
    final status = await permissions.cameraStatus();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!context.mounted) return false;
      await _showSettingsRationale(
        context,
        icon: Icons.videocam_off_rounded,
        title: 'Camera access disabled',
        body: 'Camera access is disabled in system settings. Relay requires camera access for video calls.',
        onOpenSettings: permissions.openSettings,
      );
      return false;
    }

    if (!context.mounted) return false;
    final proceed = await _showRequestRationale(
      context,
      icon: Icons.videocam_rounded,
      title: 'Allow camera access?',
      body: 'Relay uses your camera for video calls. Camera access is only used while a video call needs it.',
      continueLabel: 'Continue',
      cancelLabel: 'Not now',
    );

    if (!proceed) {
      return false;
    }

    final result = await permissions.requestCamera();
    return result.isGranted;
  }

  static Future<bool> _showRequestRationale(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required String continueLabel,
    required String cancelLabel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(RelaySpacing.lg, RelaySpacing.xs, RelaySpacing.lg, RelaySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.surfaceContainer,
                  child: Icon(icon, size: 28, color: colors.primary),
                ),
                const SizedBox(height: RelaySpacing.md),
                Text(
                  title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colors.onSurface),
                ),
                const SizedBox(height: RelaySpacing.sm),
                Text(body, style: TextStyle(fontSize: 15, height: 1.45, color: colors.onSurfaceVariant)),
                const SizedBox(height: RelaySpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, RelaySizes.minimumTouchTarget),
                        padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.md),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(sheetContext, false);
                      },
                      child: Text(cancelLabel),
                    ),
                    const SizedBox(width: RelaySpacing.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, RelaySizes.minimumTouchTarget),
                        padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.lg),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(sheetContext, true);
                      },
                      child: Text(continueLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  static Future<void> _showSettingsRationale(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required Future<bool> Function() onOpenSettings,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(RelaySpacing.lg, RelaySpacing.xs, RelaySpacing.lg, RelaySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.surfaceContainer,
                  child: Icon(icon, size: 28, color: colors.error),
                ),
                const SizedBox(height: RelaySpacing.md),
                Text(
                  title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colors.onSurface),
                ),
                const SizedBox(height: RelaySpacing.sm),
                Text(body, style: TextStyle(fontSize: 15, height: 1.45, color: colors.onSurfaceVariant)),
                const SizedBox(height: RelaySpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, RelaySizes.minimumTouchTarget),
                        padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.md),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: RelaySpacing.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, RelaySizes.minimumTouchTarget),
                        padding: const EdgeInsets.symmetric(horizontal: RelaySpacing.lg),
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(sheetContext);
                        await onOpenSettings();
                      },
                      child: const Text('Open settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
