import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';

class ChooseNameScreen extends StatefulWidget {
  const ChooseNameScreen({super.key});

  @override
  State<ChooseNameScreen> createState() => _ChooseNameScreenState();
}

class _ChooseNameScreenState extends State<ChooseNameScreen> {
  String? _username;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    if (app.usernameLocked) {
      _username = app.nickname;
    } else {
      _username = app.generateUniqueUsername();
      app.assignUsername(_username!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final username = _username ?? app.nickname;

    return ScreenWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text('Your username', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 6),
          const Text(
            'A unique anonymous name — assigned once and cannot be changed',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                UserAvatar(name: username, radius: 40),
                const SizedBox(height: 16),
                Text(username, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: AppColors.textDim),
                      SizedBox(width: 6),
                      Text('Permanent — cannot be changed', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryButton(
            title: 'Continue →',
            onPressed: () => context.go('/onboarding/safety'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
