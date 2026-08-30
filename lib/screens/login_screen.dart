import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../services/master_data_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import '../features/registration/register_user_screen.dart';
import '../models/user_role.dart';

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
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter both username and password.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<AuthService>().login(username, password);
      if (!mounted) return;
      final role = context.read<AuthService>().role;

      // Marketplace accounts never touch the internal harvest-ops queues,
      // so skip bootstrapping master data / cases for them entirely —
      // those screens (and this cache) belong to the other 10 roles only.
      if (role != null && role.isMarketplaceRole) {
        // Nothing to eagerly bootstrap — the marketplace dashboard and its
        // screens each fetch their own data on demand.
      } else {
        // Bootstrap the two datasets almost every screen reads synchronously
        // off local cache — master data (dropdowns) and cases (queues/lists)
        // — so the dashboard and every stage screen behind it work exactly
        // as they did against the old in-memory mock data.
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
        const SnackBar(content: Text('Could not reach the server. Check your connection and try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.agriculture, size: 56, color: AppTheme.primary),
                const SizedBox(height: 12),
                Text(
                  'HarvestFlow',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Harvesting Planning, Purchase, Sales & Logistics',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  enabled: !_submitting,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _login,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Log In'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          ),
                  child: const Text('Forgot password?'),
                ),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterUserScreen()),
                          ),
                  child: const Text('Register User'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your role is assigned by your account — there\'s no role picker here anymore, '
                  'the backend returns it from your credentials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
