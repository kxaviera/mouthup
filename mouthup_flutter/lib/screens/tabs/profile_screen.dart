import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/nav_back.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';

enum ProfileRoute {
  myPosts('/profile/posts'),
  saved('/profile/saved'),
  blocked('/profile/blocked'),
  terms('/profile/terms'),
  privacy('/profile/privacy');

  const ProfileRoute(this.path);
  final String path;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete account?', style: TextStyle(color: AppColors.text)),
        content: const Text('All data will be deleted. This cannot be undone.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.text),
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context.read<AppState>().deleteAccount();
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrGo(context, '/home');
      },
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => popOrGo(context, '/home'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                  const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(name: app.nickname, radius: 36),
                        const SizedBox(height: 14),
                        Text(app.nickname, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('Anonymous · username locked forever', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        if (app.email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(app.email, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                        ],
                        const SizedBox(height: 18),
                        _stat('${app.myPosts.length}', 'Posts', () => context.push(ProfileRoute.myPosts.path)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                  _menuRow(context, Icons.article_outlined, 'My posts', '${app.myPosts.length} post${app.myPosts.length == 1 ? '' : 's'}', () => context.push(ProfileRoute.myPosts.path)),
                  _menuRow(context, Icons.bookmark_outline, 'Saved', '${app.savedPosts.length} saved', () => context.push(ProfileRoute.saved.path)),
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                  _menuRow(context, Icons.block, 'Blocked users', '${app.blockedUsers.length} blocked', () => context.push(ProfileRoute.blocked.path)),
                  _menuRow(context, Icons.description_outlined, 'Terms & Conditions', null, () => context.push(ProfileRoute.terms.path)),
                  _menuRow(context, Icons.privacy_tip_outlined, 'Privacy Policy', null, () => context.push(ProfileRoute.privacy.path)),
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                  _menuRow(context, Icons.logout, 'Logout', null, () async {
                    await context.read<AppState>().logout();
                    if (!context.mounted) return;
                    context.go('/login');
                  }, danger: false),
                  _menuRow(context, Icons.delete_outline, 'Delete account', 'Permanent', () => _confirmDelete(context), danger: true),
                  const SizedBox(height: 32),
                  const Center(child: Text('MouthUp v1.0', style: TextStyle(color: AppColors.textDim, fontSize: 12))),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _menuRow(BuildContext context, IconData icon, String title, String? subtitle, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: danger ? AppColors.danger : AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: danger ? AppColors.danger : AppColors.text, fontSize: 15, fontWeight: FontWeight.w600)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: danger ? AppColors.danger : AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}
