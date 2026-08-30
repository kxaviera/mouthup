import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_profile_nav.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/social_profile_body.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.username});

  final String username;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadPublicProfile(widget.username);
    });
  }

  Future<void> _toggleFollow(AppState app) async {
    setState(() => _followLoading = true);
    await app.toggleFollow(widget.username);
    if (mounted) setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (app.isSelf(widget.username)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/profile');
      });
      return const SizedBox.shrink();
    }

    if (!app.canViewProfile(widget.username)) {
      return ScreenWrapper(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
              ],
            ),
            const Expanded(
              child: Center(child: Text('This profile is unavailable', style: TextStyle(color: AppColors.textMuted))),
            ),
          ],
        ),
      );
    }

    final canMessage = app.canDm(widget.username);

    return PopScope(
      canPop: true,
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
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                  const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.text),
                    color: AppColors.bgCard,
                    onSelected: (value) async {
                      if (value == 'block') {
                        final error = await app.blockUser(widget.username);
                        if (!context.mounted) return;
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error ?? '${widget.username} blocked')),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'block', child: Text('Block user', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SocialProfileBody(
                app: app,
                username: widget.username,
                isSelf: false,
                followLoading: _followLoading,
                onFollow: () => _toggleFollow(app),
                onMessage: canMessage ? () => openDirectChat(context, app, widget.username) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
