import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/providers/call_controller.dart';
import 'package:relay/features/call/models/call_lifecycle.dart';
import 'package:relay/features/home/widgets/home_action_card.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:relay/features/sip/sip_controller.dart';
import 'package:relay/shared/permissions/relay_permissions.dart';
import 'package:relay/shared/widgets/relay_permission_sheet.dart';
import 'package:relay/shared/widgets/relay_status_pill.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final destination = TextEditingController();

  @override
  void dispose() {
    destination.dispose();
    super.dispose();
  }

  Future<void> start(String mode) async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    final peer = destination.text.trim();
    if (peer.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a destination extension before calling.')));
      return;
    }

    final config = ref.read(sipControllerProvider.notifier).currentConfig;
    if (config.isConfigured && _isOwnDestination(peer, config)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't call your own account.")),
      );
      return;
    }

    if (mode == 'audio') {
      final isRegistered = ref.read(sipControllerProvider).isRegistered;
      if (!isRegistered) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please register your SIP account in Settings before calling.')));
        return;
      }

      final permissions = ref.read(relayPermissionsProvider);
      final granted = await RelayPermissionSheet.ensureMicrophone(context, permissions);
      if (!granted) {
        if (mounted) {
          final status = await permissions.microphoneStatus();
          if (!mounted) return;
          if (status.isDenied) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Microphone permission is required to make calls.')));
          }
        }
        return;
      }

      if (!mounted) return;
      ref.read(callControllerProvider.notifier).startAudioCall(peer);
      context.push(Uri(path: '/call', queryParameters: {'mode': 'audio'}).toString());
      return;
    }

    if (mode == 'video') {
      final isRegistered = ref.read(sipControllerProvider).isRegistered;
      if (!isRegistered) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please register your SIP account in Settings before calling.')));
        return;
      }

      final permissions = ref.read(relayPermissionsProvider);
      final micGranted = await RelayPermissionSheet.ensureMicrophone(context, permissions);
      if (!micGranted) {
        if (mounted) {
          final status = await permissions.microphoneStatus();
          if (!mounted) return;
          if (status.isDenied) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Microphone permission is required to make calls.')));
          }
        }
        return;
      }

      if (!mounted) return;
      final camGranted = await RelayPermissionSheet.ensureCamera(context, permissions);
      if (!camGranted) {
        if (mounted) {
          final status = await permissions.cameraStatus();
          if (!mounted) return;
          if (status.isDenied) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Camera permission is required for video calls.')));
          }
        }
        return;
      }

      if (!mounted) return;
      final success = await ref.read(callControllerProvider.notifier).startVideoCall(peer);
      if (success && mounted) {
        context.push(Uri(path: '/call', queryParameters: {'mode': 'video'}).toString());
      }
      return;
    }

    context.push(Uri(path: '/call', queryParameters: {'mode': mode}).toString());
  }

  bool _isOwnDestination(String destination, SipAccountConfig config) {
    final entered = destination.trim();
    final ownExtension = config.extension.trim();
    if (ownExtension.isEmpty) return false;

    String userPart(String value) {
      final withoutScheme = value.replaceFirst(RegExp(r'^sips?:', caseSensitive: false), '');
      return withoutScheme.split('@').first.trim();
    }

    final enteredUser = userPart(entered);
    final ownUser = userPart(ownExtension);
    if (enteredUser.isEmpty || ownUser.isEmpty) return false;
    if (enteredUser.toLowerCase() == ownUser.toLowerCase()) return true;

    final enteredUri = entered.toLowerCase();
    final ownUri = config.sipUri.toLowerCase();
    return enteredUri == ownUri;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final registrationState = ref.watch(sipControllerProvider);
    final sipConfig = ref.watch(sipControllerProvider.notifier).currentConfig;
    final callState = ref.watch(callControllerProvider);
    final hasActiveCall = !callState.session.isEnded &&
        (callState.session.isActive || callState.session.isConnecting ||
            callState.session.lifecycle == CallLifecycle.incoming);
    final statusColor = switch (registrationState.status) {
      SipRegistrationStatus.registered => colors.tertiary,
      SipRegistrationStatus.connecting => colors.primary,
      SipRegistrationStatus.failed => colors.error,
      SipRegistrationStatus.idle || SipRegistrationStatus.disconnected => colors.outline,
    };

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (constraints.maxHeight - 36).clamp(0, double.infinity)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/logo.png', width: 40, height: 40, semanticLabel: 'Relay mark'),
                          const SizedBox(width: RelaySpacing.sm + 2),
                          const Expanded(
                            child: Text(
                              'Relay',
                              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700, letterSpacing: -1),
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Settings',
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.settings_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: colors.surfaceContainer,
                              minimumSize: const Size(RelaySizes.minimumTouchTarget, RelaySizes.minimumTouchTarget),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: constraints.maxHeight < 700 ? 40 : 66),
                      Text(
                        registrationState.isRegistered
                            ? 'Ready to connect.'
                            : sipConfig.isConfigured
                            ? "You're offline."
                            : 'Set up Relay.',
                        style: const TextStyle(
                          fontSize: 46,
                          height: 1.08,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: RelaySpacing.md + 2),
                      Text(
                        registrationState.isRegistered
                            ? 'Start an audio call or video call.'
                            : sipConfig.isConfigured
                            ? 'Relay is disconnected from your account.'
                            : 'Connect your account to start making and receiving calls.',
                        style: TextStyle(fontSize: 17, height: 1.5, color: colors.onSurfaceVariant),
                      ),
                      if (!registrationState.isRegistered) ...[
                        const SizedBox(height: RelaySpacing.xl - 2),
                        if (!sipConfig.isConfigured)
                          FilledButton.icon(
                            onPressed: () => context.push('/settings/sip-account'),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Set up account'),
                            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                          )
                        else ...[
                          RelayStatusPill(registrationState.homeStatusLabel, color: statusColor),
                          const SizedBox(height: RelaySpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/settings/sip-account'),
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: const Text('Account settings'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                          ),
                        ],
                      ],
                      if (hasActiveCall) ...[
                        const SizedBox(height: RelaySpacing.md),
                        FilledButton.icon(
                          onPressed: () => context.push('/call'),
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('Return to call'),
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                        ),
                        const SizedBox(height: RelaySpacing.md),
                      ],
                      const SizedBox(height: RelaySpacing.xl - 2),
                      TextField(
                        controller: destination,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        maxLength: 32,
                        style: const TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: 'Contact ID',
                          hintText: 'e.g. 1002',
                          helper: const Text('Enter an extension, e.g. 1002.', softWrap: true),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          prefixIcon: const Icon(Icons.tag_rounded),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: destination,
                            builder: (context, value, _) {
                              final reducedMotion = MediaQuery.disableAnimationsOf(context);
                              return AnimatedSwitcher(
                                duration: reducedMotion ? Duration.zero : RelayDuration.fast,
                                child: value.text.isNotEmpty
                                    ? IconButton(
                                        key: const ValueKey('clear_destination'),
                                        tooltip: 'Clear destination',
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: destination.clear,
                                      )
                                    : const SizedBox.shrink(key: ValueKey('empty_destination')),
                              );
                            },
                          ),
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 22),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(RelayRadius.lg - 4),
                            borderSide: BorderSide(color: colors.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(RelayRadius.lg - 4),
                            borderSide: BorderSide(color: colors.outlineVariant),
                          ),
                        ),
                      ),
                      const SizedBox(height: RelaySpacing.lg - 2),
                      HomeActionCard(
                        label: 'Audio call',
                        icon: Icons.call_rounded,
                        background: colors.primary,
                        foreground: colors.onPrimary,
                        onTap: registrationState.isRegistered
                            ? () => start('audio')
                            : () => context.push('/settings/sip-account'),
                      ),
                      const SizedBox(height: RelaySpacing.sm + 4),
                      HomeActionCard(
                        label: 'Video call',
                        icon: Icons.videocam_rounded,
                        background: colors.primaryContainer,
                        foreground: colors.onPrimaryContainer,
                        onTap: registrationState.isRegistered
                            ? () => start('video')
                            : () => context.push('/settings/sip-account'),
                      ),
                      const SizedBox(height: RelaySpacing.xxl),
                      RelayStatusPill(registrationState.homeStatusLabel, color: statusColor),
                      const SizedBox(height: RelaySpacing.sm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
