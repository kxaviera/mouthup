import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

class ProfileHeaderButton extends StatelessWidget {
  const ProfileHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return UserAvatar(
      name: app.displayName,
      imageUrl: app.profileAvatarUrl,
      verified: app.userVerified,
      radius: 16,
      onTap: () => context.push('/profile'),
    );
  }
}

class ProfileHeaderRow extends StatelessWidget {
  const ProfileHeaderRow({
    super.key,
    required this.title,
    this.trailing,
    this.showProfile = true,
  });

  final Widget title;
  final Widget? trailing;
  final bool showProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showProfile) ...[
            const ProfileHeaderButton(),
            const SizedBox(width: 10),
          ],
          Expanded(child: title),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
