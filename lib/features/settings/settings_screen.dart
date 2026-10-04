import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/shared/widgets/relay_section.dart';
import 'package:relay/shared/widgets/relay_settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final metadata = PackageInfo.fromPlatform();
  String microphone = 'Default';
  String camera = 'Front';
  String output = 'Default';
  bool mirrorSelfView = true;
  String videoQuality = 'Auto';

  void choose(
    String title,
    List<String> options,
    String selected,
    ValueChanged<String> update,
  ) {
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option),
                  trailing: option == selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Settings',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
      ),
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
                onTap: () => choose(
                  'Microphone',
                  ['Default', 'Phone microphone', 'Bluetooth microphone'],
                  microphone,
                  (value) => setState(() => microphone = value),
                ),
              ),
              RelaySettingsTile(
                icon: Icons.videocam_rounded,
                title: 'Camera',
                onTap: () => choose(
                  'Camera',
                  ['Front', 'Back'],
                  camera,
                  (value) => setState(() => camera = value),
                ),
              ),
              RelaySettingsTile(
                icon: Icons.volume_up_rounded,
                title: 'Audio output',
                divider: false,
                onTap: () => choose(
                  'Audio output',
                  ['Default', 'Earpiece', 'Speaker', 'Bluetooth'],
                  output,
                  (value) => setState(() => output = value),
                ),
              ),
            ],
          ),
          RelaySection(
            title: 'Video',
            children: [
              RelaySettingsTile(
                icon: Icons.flip_camera_android_outlined,
                title: 'Mirror self view',
                trailing: Switch(
                  value: mirrorSelfView,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => mirrorSelfView = value);
                  },
                ),
              ),
              RelaySettingsTile(
                icon: Icons.signal_cellular_alt_rounded,
                title: 'Video quality',
                value: videoQuality,
                divider: false,
                onTap: () => choose(
                  'Video quality',
                  ['Auto', '720p', '1080p'],
                  videoQuality,
                  (value) => setState(() => videoQuality = value),
                ),
              ),
            ],
          ),
          RelaySection(
            title: 'Connection',
            children: [
              RelaySettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'SIP account',
                onTap: () => information(
                  'SIP account',
                  'Extension 1001\nRegistration: Registered\nTransport: WSS\n\nPreview connection values only.',
                ),
              ),
              RelaySettingsTile(
                icon: Icons.dns_outlined,
                title: 'ICE servers',
                onTap: () => information(
                  'ICE servers',
                  'STUN and TURN configuration will be available here. No server connection is active in this preview.',
                ),
              ),
              RelaySettingsTile(
                icon: Icons.science_outlined,
                title: 'RTC Lab',
                divider: false,
                onTap: () => context.push('/rtc-lab'),
              ),
            ],
          ),
          RelaySection(
            title: 'About',
            children: [
              RelaySettingsTile(
                icon: Icons.hub_outlined,
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
                  value: snapshot.hasData
                      ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                      : '—',
                  onTap: () => information(
                    'Version',
                    snapshot.hasData
                        ? '${snapshot.data!.appName}\n${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                        : 'Version information is unavailable.',
                  ),
                ),
              ),
              RelaySettingsTile(
                icon: Icons.code_rounded,
                title: 'GitHub',
                divider: false,
                onTap: () => information(
                  'GitHub',
                  'Relay is a learning and reference application. The project source link will be available here.',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
