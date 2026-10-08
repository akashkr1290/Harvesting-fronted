import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../services/master_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_selector_widget.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import '../features/registration/register_user_screen.dart';
import '../models/user_role.dart';
import '../services/localization_service.dart';
import '../services/voice_service.dart';
import '../widgets/simple/simple_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final loc = context.read<LocalizationService>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('enter_username_password'))),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<AuthService>().login(username, password);
      if (!mounted) return;
      final role = context.read<AuthService>().role;

      if (role != null && role.isMarketplaceRole) {
        // Marketplace accounts fetch data on demand
      } else {
        await Future.wait([
          context.read<MasterDataService>().fetchAll(),
          context.read<CaseService>().fetchAll(),
        ]);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('server_error'))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    if (!loc.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!loc.languageChosen) {
      return const _LanguageFirstScreen();
    }

    String speech() => '${loc.t('mobile_or_username')}. ${loc.t('pin_or_password')}. ${loc.t('login_btn')}.';

    return Scaffold(
      backgroundColor: SimpleColors.ground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const LanguageSelectorWidget(),
                    const Spacer(),
                    SpeakButton(text: speech),
                  ]),
                  const SizedBox(height: 16),
                  const Icon(Icons.agriculture, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    loc.t('app_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _usernameController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: loc.t('mobile_or_username'),
                      helperText: loc.t('mobile_or_username_hint'),
                      helperMaxLines: 2,
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 28),
                      suffixIcon: IconButton(
                        tooltip: loc.t('speak_number'),
                        iconSize: 28,
                        icon: const Icon(Icons.mic_rounded, color: AppTheme.primary),
                        onPressed: _submitting ? null : _speakMobile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    enabled: !_submitting,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    style: const TextStyle(fontSize: 22, letterSpacing: 4),
                    decoration: InputDecoration(
                      labelText: loc.t('pin_or_password'),
                      prefixIcon: const Icon(Icons.lock_rounded, size: 28),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BigButton(
                    label: loc.t('login_btn'),
                    icon: Icons.login_rounded,
                    busy: _submitting,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 12),
                  BigButton(
                    label: loc.t('new_here_register'),
                    icon: Icons.person_add_alt_1_rounded,
                    outlined: true,
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterUserScreen()),
                            ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            ),
                    child: Text(loc.t('forgot_pin'), style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(height: 8),
                  const HelpCallButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _speakMobile() async {
    final loc = context.read<LocalizationService>();
    final heard = await context.read<VoiceService>().listen(localeId: loc.speechLocaleId);
    final digits = (heard ?? '').replaceAll(RegExp(r'[^0-9०-९]'), '');
    if (digits.isNotEmpty && mounted) {
      const dev = '०१२३४५६७८९';
      final ascii = digits.split('').map((c) => dev.contains(c) ? dev.indexOf(c).toString() : c).join();
      setState(() => _usernameController.text = ascii);
    }
  }
}

/// First launch: pick the language by its own script, big buttons, before anything else.
class _LanguageFirstScreen extends StatelessWidget {
  const _LanguageFirstScreen();

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      backgroundColor: SimpleColors.ground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              children: [
                const Icon(Icons.translate_rounded, size: 56, color: SimpleColors.green),
                const SizedBox(height: 8),
                const Text('अपनी भाषा चुनें · Choose your language',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SimpleColors.ink)),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: [
                    for (final lang in supportedLanguages)
                      Semantics(
                        button: true,
                        label: '${lang.nativeName} ${lang.name}',
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              loc.setLanguage(lang.locale);
                              context.read<VoiceService>().speak(lang.nativeName, language: '${lang.locale.languageCode}-IN');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: SimpleColors.line, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Text(lang.nativeName,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: SimpleColors.ink)),
                                Text(lang.name, style: const TextStyle(fontSize: 14, color: SimpleColors.quiet)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
