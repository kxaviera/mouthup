import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/nav_back.dart';
import '../../utils/notification_nav.dart';
import '../../widgets/screen_wrapper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppState>().refreshNotifications();
      if (mounted) setState(() => _loading = false);
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.listing:
        return Icons.storefront_outlined;
      case NotificationType.message:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.comment:
        return Icons.mode_comment_outlined;
      case NotificationType.follow:
        return Icons.person_add_alt_1_outlined;
      case NotificationType.general:
        return Icons.notifications_none_rounded;
    }
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
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : items.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final n = items[i];
                            final hasRoute = resolveNotificationRoute(n.route) != null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: n.read ? AppColors.bgCard : AppColors.bgElevated,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: () async {
                                    if (hasRoute) {
                                      await openNotificationRoute(context, n);
                                    } else {
                                      app.markNotificationRead(n.id);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: n.read ? AppColors.border : AppColors.primary.withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.bg,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Icon(_icon(n.type), color: AppColors.text, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      n.title,
                                                      style: TextStyle(
                                                        color: AppColors.text,
                                                        fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!n.read)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      margin: const EdgeInsets.only(left: 6),
                                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(n.body, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.35)),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text(_timeAgo(n.createdAt), style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                                  if (hasRoute) ...[
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '· ${notificationActionLabel(n.type)}',
                                                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (hasRoute)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4, top: 2),
                                            child: Icon(Icons.chevron_right, color: AppColors.textDim, size: 20),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 36, color: AppColors.textDim),
            ),
            const SizedBox(height: 16),
            const Text('No notifications yet', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Messages, replies, and listing activity will show up here',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
