import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/providers/call_controller.dart';
import 'package:relay/features/home/widgets/home_action_card.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:relay/features/sip/sip_controller.dart';
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

  void start(String mode) {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    final peer = destination.text.trim();
    if (peer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination extension before calling.')),
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
      ref.read(callControllerProvider.notifier).startAudioCall(peer);
      context.push(Uri(path: '/call', queryParameters: {'mode': 'audio'}).toString());
      return;
    }

    context.push(
      Uri(
        path: '/call',
        queryParameters: {'mode': mode},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final registrationState = ref.watch(sipControllerProvider);
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
                      const Text(
                        'Ready to\nconnect',
                        style: TextStyle(fontSize: 46, height: 1.08, fontWeight: FontWeight.w600, letterSpacing: -2),
                      ),
                      const SizedBox(height: RelaySpacing.md + 2),
                      Text(
                        'Start an audio call or video call.',
                        style: TextStyle(fontSize: 17, height: 1.5, color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: RelaySpacing.xl - 2),
                      TextField(
                        controller: destination,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        maxLength: 32,
                        style: const TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: 'Destination',
                          hintText: 'e.g. 1002',
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
                        onTap: () => start('audio'),
                      ),
                      const SizedBox(height: RelaySpacing.sm + 4),
                      HomeActionCard(
                        label: 'Video call',
                        icon: Icons.videocam_rounded,
                        background: colors.primaryContainer,
                        foreground: colors.onPrimaryContainer,
                        onTap: () => start('video'),
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
