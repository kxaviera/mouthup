import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email')));
      return;
    }
    final error = await context.read<AppState>().requestPasswordReset(email);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.push('/reset-password?email=${Uri.encodeComponent(email)}');
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
          const Text('Forgot password?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('Enter your email and we\'ll send a reset code.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 28),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.textDim)),
          ),
          const SizedBox(height: 24),
          PrimaryButton(title: 'Send reset code', onPressed: _sendCode),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
