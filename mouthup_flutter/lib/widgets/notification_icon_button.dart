import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
            backgroundColor: AppColors.primary,
            textColor: AppColors.onPrimary,
            offset: const Offset(6, -6),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.text,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
