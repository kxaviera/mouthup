import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/firebase_auth_service.dart';
import '../../constants/app_brand.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mouthup_logo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _signup() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email')));
      return;
    }
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _loading = true);
    final error = await context.read<AppState>().signup(emailInput: email, password: _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final app = context.read<AppState>();
    if (app.onboardingDone) {
      context.go('/home');
    } else if (!app.emailVerified) {
      context.go('/verify-email');
    } else {
      context.go('/onboarding/nickname');
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _loading = true);
    final error = await context.read<AppState>().loginWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (!context.read<AppState>().isLoggedIn) return;
    final app = context.read<AppState>();
    if (app.onboardingDone) {
      context.go('/home');
    } else {
      context.go('/onboarding/nickname');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      scrollable: true,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IconButton(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back, color: AppColors.textMuted),
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 8),
            const Center(child: IsziFullLogo(size: 72)),
            const SizedBox(height: 20),
            const Text('Create account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            const Text('Sign up with email — you\'ll pick a username and screen name next', style: TextStyle(color: AppColors.textMuted)),
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
            const SizedBox(height: 14),
            TextField(
              controller: _confirm,
              obscureText: true,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.textDim)),
            ),
            const SizedBox(height: 24),
            PrimaryButton(title: _loading ? 'Creating account…' : 'Sign up', onPressed: _loading ? null : _signup),
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
                onPressed: _loading ? null : _signupWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.text),
                label: const Text('Sign up with Google', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'By signing up you agree to community guidelines & 18+ age',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
    );
  }
}
