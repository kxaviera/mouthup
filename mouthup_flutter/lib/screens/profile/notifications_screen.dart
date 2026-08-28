import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../widgets/screen_wrapper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshNotifications();
    });
  }

  void _openNotification(BuildContext context, AppNotification n) {
    context.read<AppState>().markNotificationRead(n.id);
    final route = n.route;
    if (route != null && route.isNotEmpty) {
      if (route.startsWith('/messages/')) {
        context.push(route.replaceFirst('/messages/', '/chats/'));
      } else {
        context.push(route);
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.notifications;

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
            Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => popOrGo(context, '/home'),
                    icon: const Icon(Icons.arrow_back, color: AppColors.text),
                  ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                  ),
                  if (app.unreadNotificationCount > 0)
                    TextButton(onPressed: app.markAllNotificationsRead, child: const Text('Mark all read')),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        app.lastError ?? 'No notifications yet',
                        style: const TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final n = items[i];
                        return ListTile(
                          onTap: () => _openNotification(context, n),
                          tileColor: n.read ? null : AppColors.bgElevated.withValues(alpha: 0.35),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(n.body, style: const TextStyle(color: AppColors.textMuted)),
                          trailing: Text(_timeAgo(n.createdAt), style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
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
