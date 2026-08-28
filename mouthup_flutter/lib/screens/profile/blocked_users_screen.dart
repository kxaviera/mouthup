import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_wrapper.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshBlocked();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/profile');
      },
      child: ScreenWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(onPressed: () => context.go('/profile'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                const Text('Blocked users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Blocked users won\'t appear in your feed or messages', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            if (app.blockedUsers.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, size: 48, color: AppColors.textDim),
                      SizedBox(height: 12),
                      Text('No blocked users', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: app.blockedUsers.length,
                  itemBuilder: (_, i) {
                    final u = app.blockedUsers[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(u.nickname, style: const TextStyle(color: AppColors.text)),
                      trailing: TextButton(
                        onPressed: () async {
                          final error = await app.unblockUser(u.nickname);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error ?? '${u.nickname} unblocked')),
                          );
                        },
                        child: const Text('Unblock'),
                      ),
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
