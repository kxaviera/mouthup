import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    final error = await context.read<AppState>().resetPassword(
          email: widget.email,
          code: _code.text.trim(),
          newPassword: _password.text,
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            IconButton(
              onPressed: () => context.go('/forgot-password'),
              icon: const Icon(Icons.arrow_back, color: AppColors.textMuted),
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 8),
            const Text('Reset password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Text('Code sent to ${widget.email}', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Reset code', prefixIcon: Icon(Icons.pin_outlined, color: AppColors.textDim)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'New password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.textDim)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirm,
              obscureText: true,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.textDim)),
            ),
            const SizedBox(height: 24),
            PrimaryButton(title: 'Update password', onPressed: _reset),
            const SizedBox(height: 24),
          ],
        ),
    );
  }
}
