import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/nav_back.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/social_profile_body.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.inTabShell = false});

  final bool inTabShell;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PopScope(
      canPop: !inTabShell,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !inTabShell) return;
        context.go('/home');
      },
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(inTabShell ? 16 : 4, 4, 8, 0),
              child: Row(
                children: [
                  if (!inTabShell)
                    IconButton(
                      onPressed: () => popOrGo(context, '/home'),
                      icon: const Icon(Icons.arrow_back, color: AppColors.text),
                    ),
                  const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.text),
                    onPressed: () => context.push('/profile/settings'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SocialProfileBody(
                app: app,
                username: app.nickname,
                isSelf: true,
                onEditPhoto: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo upload coming soon')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
