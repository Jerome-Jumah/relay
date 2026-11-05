import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/sip/models/sip_account_config.dart';
import 'package:relay/features/sip/models/sip_registration_state.dart';
import 'package:relay/features/sip/sip_controller.dart';
import 'package:relay/shared/widgets/relay_section.dart';
import 'package:relay/shared/widgets/relay_status_pill.dart';

class SipAccountScreen extends ConsumerStatefulWidget {
  const SipAccountScreen({super.key});

  @override
  ConsumerState<SipAccountScreen> createState() => _SipAccountScreenState();
}

class _SipAccountScreenState extends ConsumerState<SipAccountScreen> {
  late final TextEditingController _serverController;
  late final TextEditingController _extensionController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController();
    _extensionController = TextEditingController();
    _passwordController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialConfig());
  }

  Future<void> _loadInitialConfig() async {
    final config = await ref.read(sipControllerProvider.notifier).loadConfig();
    if (!mounted) return;
    setState(() {
      _serverController.text = config.webSocketUrl.isNotEmpty
          ? config.webSocketUrl
          : SipAccountConfig.defaultWebSocketUrl;
      _extensionController.text = config.extension;
      _passwordController.text = config.password;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _extensionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSaveAndConnect() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    String rawServer = _serverController.text.trim();
    if (rawServer.isEmpty) {
      rawServer = SipAccountConfig.defaultWebSocketUrl;
    } else if (!rawServer.startsWith('ws://') &&
        !rawServer.startsWith('wss://')) {
      rawServer = 'wss://$rawServer';
    }

    final uri = Uri.tryParse(rawServer);
    final domain = (uri != null && uri.host.isNotEmpty)
        ? uri.host
        : SipAccountConfig.defaultDomain;

    final config = SipAccountConfig(
      webSocketUrl: rawServer,
      domain: domain,
      extension: _extensionController.text.trim(),
      password: _passwordController.text,
    );

    await ref.read(sipControllerProvider.notifier).saveAndRegister(config);
  }

  Future<void> _onDisconnect() async {
    HapticFeedback.lightImpact();
    await ref.read(sipControllerProvider.notifier).unregister();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final registrationState = ref.watch(sipControllerProvider);

    final statusColor = switch (registrationState.status) {
      SipRegistrationStatus.registered => colors.tertiary,
      SipRegistrationStatus.connecting => colors.primary,
      SipRegistrationStatus.failed => colors.error,
      SipRegistrationStatus.idle ||
      SipRegistrationStatus.disconnected => colors.outline,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SIP account',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              RelaySpacing.md + 4,
              RelaySpacing.md + 4,
              RelaySpacing.md + 4,
              RelaySpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RelaySection(
                      title: 'Status',
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(RelaySpacing.md, RelaySpacing.sm, RelaySpacing.md, 0),
                          child: Text(
                            'Connection status indicates whether Relay is registered and ready to receive calls.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(RelaySpacing.md),
                          child: Row(
                            children: [
                              RelayStatusPill(
                                registrationState.displayLabel,
                                color: statusColor,
                                filled: true,
                              ),
                            ],
                          ),
                        ),
                        if (registrationState.status ==
                                SipRegistrationStatus.failed &&
                            registrationState.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              RelaySpacing.md,
                              0,
                              RelaySpacing.md,
                              RelaySpacing.md,
                            ),
                            child: Text(
                              registrationState.errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    RelaySection(
                      title: 'Configuration',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(RelaySpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _serverController,
                                enabled: _initialized,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'WebSocket server',
                                  hintText: 'wss://sip.code4flare.com',
                                  prefixIcon: const Icon(Icons.dns_outlined),
                                  filled: false,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      RelayRadius.md,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      RelayRadius.md,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: RelaySpacing.md),
                              TextField(
                                controller: _extensionController,
                                enabled: _initialized,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Extension',
                                  hintText: '1001',
                                  prefixIcon: const Icon(Icons.tag_rounded),
                                  filled: false,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      RelayRadius.md,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      RelayRadius.md,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: RelaySpacing.md),
                              TextField(
                                controller: _passwordController,
                                enabled: _initialized,
                                obscureText: _obscurePassword,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
                                    },
                                  ),
                                  filled: false,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      RelayRadius.md,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      RelayRadius.md,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RelaySpacing.sm),
                    FilledButton(
                      onPressed:
                          registrationState.isConnecting ? null : _onSaveAndConnect,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(RelayRadius.md),
                        ),
                      ),
                      child: registrationState.isConnecting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: RelaySpacing.md),
                                Text(
                                  'Connecting…',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Save & connect',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    if (registrationState.isRegistered) ...[
                      const SizedBox(height: RelaySpacing.sm + 4),
                      OutlinedButton(
                        onPressed: _onDisconnect,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RelayRadius.md),
                          ),
                        ),
                        child: const Text(
                          'Disconnect',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
