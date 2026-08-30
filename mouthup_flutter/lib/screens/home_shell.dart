import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final unreadDms = app.unreadDmCount;
    final selected = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(child: _TabItem(icon: Icons.storefront_outlined, selectedIcon: Icons.storefront, label: 'Market', selected: selected == 0, onTap: () => _onTabTap(0))),
                Expanded(child: _TabItem(icon: Icons.search, selectedIcon: Icons.search, label: 'Search', selected: selected == 1, onTap: () => _onTabTap(1))),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/create-post'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(height: 2),
                        const Text('Post', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _TabItem(icon: Icons.inbox_outlined, selectedIcon: Icons.inbox, label: 'Inbox', selected: selected == 2, badge: unreadDms > 0 ? unreadDms : null, onTap: () => _onTabTap(2))),
                Expanded(child: _TabItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', selected: selected == 3, onTap: () => _onTabTap(3))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: badge != null && badge! > 0,
            label: Text(badge != null && badge! > 9 ? '9+' : '${badge ?? ''}'),
            backgroundColor: AppColors.primary,
            textColor: AppColors.onPrimary,
            child: Icon(selected ? selectedIcon : icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
