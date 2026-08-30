import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/verified_badge.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  void _confirmDelete(BuildContext context, AppState app) {
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
              final error = await app.deleteAccount();
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              context.go('/login');
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

    return ScreenWrapper(
      padding: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => popOrGo(context, '/profile'),
                  icon: const Icon(Icons.arrow_back, color: AppColors.text),
                ),
                const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _sectionTitle('Marketplace'),
                _card([
                  _row(context, Icons.storefront_outlined, 'My listings', '${app.myPosts.length} active', () => context.push('/profile/posts')),
                  _divider(),
                  _row(context, Icons.bookmark_outline, 'Saved', '${app.savedPosts.length} saved', () => context.push('/profile/saved')),
                ]),
                const SizedBox(height: 16),
                _sectionTitle('Account'),
                _card([
                  _verifiedRow(context, app),
                  _divider(),
                  _row(context, Icons.block, 'Blocked users', '${app.blockedUsers.length} blocked', () => context.push('/profile/blocked')),
                ]),
                const SizedBox(height: 16),
                _sectionTitle('Legal'),
                _card([
                  _row(context, Icons.description_outlined, 'Terms & Conditions', null, () => context.push('/profile/terms')),
                  _divider(),
                  _row(context, Icons.privacy_tip_outlined, 'Privacy Policy', null, () => context.push('/profile/privacy')),
                ]),
                const SizedBox(height: 16),
                _sectionTitle('Session'),
                _card([
                  _row(
                    context,
                    Icons.logout,
                    'Log out',
                    null,
                    () async {
                      await app.logout();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                  ),
                  _divider(),
                  _row(
                    context,
                    Icons.delete_outline,
                    'Delete account',
                    null,
                    () => _confirmDelete(context, app),
                    danger: true,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: AppColors.textDim.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.border);

  Widget _verifiedRow(BuildContext context, AppState app) {
    if (app.userVerified) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const VerifiedBadge(size: 22),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verified account', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('Your profile has the blue tick', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verified badge applications — coming soon')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: VerifiedBadge.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_outlined, color: VerifiedBadge.color, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apply for blue tick', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('Coming soon', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('Soon', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title, String? subtitle, VoidCallback onTap, {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
                  Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
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
