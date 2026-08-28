import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mouthup_logo.dart';
import 'tabs/feed_screen.dart';

/// Full-screen feed with a floating post button (no bottom bar).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: const FeedScreen(),
      floatingActionButton: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        child: InkWell(
          onTap: () => context.push('/create-post'),
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              MouthUpLogo.iconAsset,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
