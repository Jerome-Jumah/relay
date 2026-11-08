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
  final _domainController = TextEditingController();
  final _stunController = TextEditingController();
  final _turnController = TextEditingController();
  final _turnUsernameController = TextEditingController();
  final _turnPasswordController = TextEditingController();
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
    SipAccountConfig config;
    try {
      config = await ref.read(sipControllerProvider.notifier).loadConfig();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load the saved account. Reopen this screen to try again.')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _serverController.text = config.webSocketUrl.isNotEmpty
          ? config.webSocketUrl
          : SipAccountConfig.defaultWebSocketUrl;
      _extensionController.text = config.extension;
      _passwordController.text = config.password;
      _domainController.text = config.domain;
      _stunController.text = config.stunUrl;
      _turnController.text = config.turnUrl;
      _turnUsernameController.text = config.turnUsername;
      _turnPasswordController.text = config.turnPassword;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _domainController.dispose();
    _stunController.dispose();
    _turnController.dispose();
    _turnUsernameController.dispose();
    _turnPasswordController.dispose();
    _extensionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSaveAndConnect() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    final rawServer = _serverController.text.trim();

    final config = SipAccountConfig(
      webSocketUrl: rawServer,
      domain: _domainController.text.trim(),
      extension: _extensionController.text.trim(),
      password: _passwordController.text,
      stunUrl: _stunController.text.trim(),
      turnUrl: _turnController.text.trim(),
      turnUsername: _turnUsernameController.text.trim(),
      turnPassword: _turnPasswordController.text,
    );

    final error = config.validationMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await ref.read(sipControllerProvider.notifier).saveAndRegister(config);
  }

  Future<void> _onDisconnect() async {
    HapticFeedback.lightImpact();
    await ref.read(sipControllerProvider.notifier).unregister();
  }

  Widget _configurationField(
    TextEditingController controller,
    String label, {
    required IconData icon,
    String? hint,
    bool secret = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(RelayRadius.md),
      borderSide: BorderSide(color: colors.outlineVariant),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: RelaySpacing.md),
      child: TextField(
        controller: controller,
        enabled: _initialized,
        obscureText: secret,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: false,
          border: border,
          enabledBorder: border,
        ),
      ),
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
                                autocorrect: false,
                                enableSuggestions: false,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'WebSocket server',
                                  hintText: 'wss://pbx.example.org:7443',
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
                              _configurationField(
                                _domainController,
                                'SIP domain',
                                icon: Icons.language_rounded,
                                hint: 'example.org',
                              ),
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
                                autocorrect: false,
                                enableSuggestions: false,
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
                    RelaySection(
                      title: 'ICE servers (optional)',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(RelaySpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Use your own STUN/TURN servers. TURN credentials are stored securely on this device. Existing .env values must be entered here once.'),
                              const SizedBox(height: RelaySpacing.md),
                              _configurationField(
                                _stunController,
                                'STUN URL',
                                icon: Icons.dns_outlined,
                                hint: 'stun:turn.example.org:3478',
                              ),
                              _configurationField(
                                _turnController,
                                'TURN URL',
                                icon: Icons.alt_route_rounded,
                                hint: 'turn:turn.example.org:3478',
                              ),
                              _configurationField(
                                _turnUsernameController,
                                'TURN username',
                                icon: Icons.person_outline_rounded,
                              ),
                              _configurationField(
                                _turnPasswordController,
                                'TURN password',
                                icon: Icons.lock_outline_rounded,
                                secret: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RelaySpacing.sm),
                    FilledButton(
                      onPressed:
                          !_initialized || registrationState.isConnecting ? null : _onSaveAndConnect,
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
