import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/settings/models/call_preferences.dart';
import 'package:relay/features/settings/providers/call_preferences_provider.dart';
import 'package:relay/features/settings/providers/theme_mode_provider.dart';
import 'package:relay/features/settings/widgets/theme_mode_selector.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:relay/features/sip/sip_controller.dart';
import 'package:relay/shared/permissions/relay_permissions.dart';
import 'package:relay/shared/widgets/relay_permission_sheet.dart';
import 'package:relay/shared/widgets/relay_section.dart';
import 'package:relay/shared/widgets/relay_settings_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  late final metadata = PackageInfo.fromPlatform();
  bool _microphoneGranted = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final permissions = ref.read(relayPermissionsProvider);
    final mic = await permissions.isMicrophoneGranted();
    final cam = await permissions.isCameraGranted();
    if (mounted) {
      setState(() {
        _microphoneGranted = mic;
        _cameraGranted = cam;
      });
    }
  }

  void choose(String title, List<String> options, String selected, ValueChanged<String> update) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option),
                  trailing: option == selected
                      ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    update(option);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void information(String title, String body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final sipState = ref.watch(sipControllerProvider);
    final prefs = ref.watch(callPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
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
            RelaySpacing.md + 4,
            RelaySpacing.md + 4,
            RelaySpacing.md + 4,
            RelaySpacing.lg,
          ),
          children: [
            RelaySection(
              title: 'Calls',
              children: [
                RelaySettingsTile(
                  icon: Icons.mic_rounded,
                  title: 'Microphone',
                  value: _microphoneGranted ? 'Allowed' : 'Not allowed',
                  onTap: () async {
                    if (!_microphoneGranted) {
                      final permissions = ref.read(relayPermissionsProvider);
                      await RelayPermissionSheet.ensureMicrophone(context, permissions);
                      await _refreshPermissions();
                    } else {
                      information(
                        'Microphone',
                        'Microphone access is allowed. Relay uses your microphone to send audio during calls.',
                      );
                    }
                  },
                ),
                RelaySettingsTile(
                  icon: Icons.volume_up_rounded,
                  title: 'Audio route',
                  value: prefs.audioRoute,
                  divider: false,
                  onTap: () => choose(
                    'Audio route',
                    CallPreferences.supportedAudioRoutes,
                    prefs.audioRoute,
                    (value) => ref.read(callPreferencesProvider.notifier).setAudioRoute(value),
                  ),
                ),
              ],
            ),
            RelaySection(
              title: 'Video',
              children: [
                RelaySettingsTile(
                  icon: Icons.videocam_rounded,
                  title: 'Camera',
                  value: _cameraGranted ? 'Allowed' : 'Not allowed',
                  onTap: () async {
                    if (!_cameraGranted) {
                      final permissions = ref.read(relayPermissionsProvider);
                      await RelayPermissionSheet.ensureCamera(context, permissions);
                      await _refreshPermissions();
                    } else {
                      information('Camera', 'Camera access is allowed. Relay uses your camera for video calls.');
                    }
                  },
                ),
                RelaySettingsTile(
                  icon: Icons.flip_camera_android_outlined,
                  title: 'Mirror self-view',
                  trailing: Switch(
                    value: prefs.mirrorSelfView,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      ref.read(callPreferencesProvider.notifier).setMirrorSelfView(value);
                    },
                  ),
                ),
                RelaySettingsTile(
                  icon: Icons.signal_cellular_alt_rounded,
                  title: 'Video quality',
                  value: prefs.videoQuality,
                  divider: false,
                  onTap: () => choose(
                    'Video quality',
                    CallPreferences.supportedVideoQualities,
                    prefs.videoQuality,
                    (value) => ref.read(callPreferencesProvider.notifier).setVideoQuality(value),
                  ),
                ),
              ],
            ),
            RelaySection(
              title: 'Appearance',
              children: [
                RelaySettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  value: switch (themeMode) {
                    ThemeMode.system => 'System',
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                  },
                  divider: false,
                  onTap: () => ThemeModeSelector.show(context),
                ),
              ],
            ),
            RelaySection(
              title: 'Connection',
              children: [
                RelaySettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'SIP account',
                  value: sipState.extension,
                  description: switch (sipState.status) {
                    SipRegistrationStatus.registered => 'Connected',
                    SipRegistrationStatus.connecting => 'Connecting…',
                    SipRegistrationStatus.failed => 'Registration failed',
                    SipRegistrationStatus.idle || SipRegistrationStatus.disconnected => 'Disconnected',
                  },
                  onTap: () => context.push('/settings/sip-account'),
                ),
                RelaySettingsTile(
                  icon: Icons.science_outlined,
                  title: 'RTC Lab',
                  description: 'Live call diagnostics',
                  divider: false,
                  onTap: () => context.push('/rtc-lab'),
                ),
              ],
            ),
            RelaySection(
              title: 'About',
              children: [
                RelaySettingsTile(
                  leading: CircleAvatar(
                    radius: 19,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        semanticLabel: 'Relay app icon',
                      ),
                    ),
                  ),
                  title: 'Relay',
                  onTap: () => information(
                    'Relay',
                    'Connect. See. Share.\n\nAudio, video and screen sharing, with a look underneath the call.',
                  ),
                ),
                FutureBuilder<PackageInfo>(
                  future: metadata,
                  builder: (context, snapshot) => RelaySettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    value: snapshot.hasData ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})' : '—',
                    onTap: () => information(
                      'Version',
                      snapshot.hasData
                          ? '${snapshot.data!.appName}\n${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                          : 'Version information is unavailable.',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
