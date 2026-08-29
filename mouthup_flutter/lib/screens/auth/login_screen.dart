import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/demo_account.dart';
import '../../providers/app_state.dart';
import '../../services/firebase_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/mouthup_logo.dart';
import '../../widgets/screen_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty) {
      _showMessage('Enter your email');
      return;
    }
    setState(() => _loading = true);
    final error = await context.read<AppState>().login(emailInput: email, password: password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      _showMessage(error);
      return;
    }
    _navigateAfterAuth();
  }

  Future<void> _loginAsDemo() async {
    setState(() => _loading = true);
    final error = await context.read<AppState>().loginAsDemo();
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      _showMessage(error);
      return;
    }
    context.go('/home');
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    final error = await context.read<AppState>().loginWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      _showMessage(error);
      return;
    }
    if (!context.read<AppState>().isLoggedIn) return;
    _navigateAfterAuth();
  }

  void _navigateAfterAuth() {
    final app = context.read<AppState>();
    if (app.onboardingDone) {
      context.go('/home');
    } else if (!app.emailVerified) {
      context.go('/verify-email');
    } else {
      context.go('/onboarding/nickname');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Center(child: MouthUpLogo(size: 72)),
            const SizedBox(height: 40),
            const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            const Text('Login to your anonymous feed', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 32),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.textDim)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.textDim)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.go('/forgot-password'), child: const Text('Forgot password?', style: TextStyle(color: AppColors.primary))),
            ),
            const SizedBox(height: 16),
            PrimaryButton(title: _loading ? 'Signing in…' : 'Login', onPressed: _loading ? null : _login),
            if (FirebaseAuthService.isAvailable) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loading ? null : _loginWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.text),
                label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loading ? null : _loginAsDemo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Column(
                  children: [
                    Text('Continue as ${DemoAccount.username}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Demo account · no sign-up needed', style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9), fontSize: 11)),
                  ],
                ),
              ),
            ],
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              Text(
                'Or use ${DemoAccount.email} / ${DemoAccount.password}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('New account? ', style: TextStyle(color: AppColors.textMuted)),
                GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: const Text('Sign up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
