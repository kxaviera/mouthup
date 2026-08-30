import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/direct_message.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../utils/user_profile_nav.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, this.inTabShell = false});

  final bool inTabShell;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadDmThreads();
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final conversations = app.dmConversations;
    final unreadDms = app.unreadDmCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.inTabShell) {
          context.go('/home');
        } else {
          popOrGo(context, '/home');
        }
      },
      child: ScreenWrapper(
        padding: false,
        bottomSafe: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  if (!widget.inTabShell)
                    IconButton(onPressed: () => popOrGo(context, '/home'), icon: const Icon(Icons.arrow_back, color: AppColors.text)),
                  const Expanded(child: Text('Messages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text))),
                  if (unreadDms > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(99)),
                      child: Text('$unreadDms new', style: const TextStyle(color: AppColors.onPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: conversations.isEmpty
                  ? const Center(child: Text('No conversations yet', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final c = conversations[i];
                        return _conversationTile(context, app, c);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationTile(BuildContext context, AppState app, DmConversation c) {
    return ListTile(
      onTap: () => context.push('/messages/chat?peer=${Uri.encodeComponent(c.peerNickname)}'),
      leading: UserAvatar(
        name: c.peerNickname,
        imageUrl: app.avatarForUser(c.peerNickname),
        radius: 24,
      ),
      title: Text(c.peerNickname, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      subtitle: Text(
        c.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: c.unread > 0 ? AppColors.text : AppColors.textMuted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_timeAgo(c.updatedAt), style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          if (c.unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
      onLongPress: () => openUserProfile(context, app, c.peerNickname),
    );
  }
}
