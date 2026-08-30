import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _verify() async {
    setState(() => _loading = true);
    final error = await context.read<AppState>().verifyEmail(_code.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.go('/onboarding/nickname');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return ScreenWrapper(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.primary),
          const SizedBox(height: 20),
          const Text('Verify your email', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to ${app.email.isEmpty ? "your email" : app.email}',
            style: const TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text('Check your email for the 6-digit code', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 28),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(color: AppColors.text, letterSpacing: 4, fontSize: 20),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: '000000', counterText: ''),
          ),
          const SizedBox(height: 16),
          PrimaryButton(title: _loading ? 'Verifying…' : 'Verify & continue', onPressed: _loading ? null : _verify),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              final error = await app.resendVerificationCode();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error ?? 'New code sent')),
              );
            },
            child: const Text('Resend code'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
