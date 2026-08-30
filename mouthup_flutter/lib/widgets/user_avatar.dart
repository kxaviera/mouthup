import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_generator.dart';
import 'verified_badge.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.imageUrl,
    this.verified = false,
    this.showStoryRing = false,
    this.onTap,
  });

  final String name;
  final double radius;
  final String? imageUrl;
  final bool verified;
  final bool showStoryRing;
  final VoidCallback? onTap;

  /// Skip generated avatar services — they look pixelated at small sizes on web.
  String? get _resolvedNetworkUrl {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.contains('ui-avatars.com')) return null;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2 + (showStoryRing ? 6 : 0),
        height: radius * 2 + (showStoryRing ? 6 : 0),
        padding: showStoryRing ? const EdgeInsets.all(3) : null,
        decoration: showStoryRing
            ? BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              )
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: showStoryRing ? AppColors.bg : Colors.white.withValues(alpha: 0.08),
                  width: showStoryRing ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _resolvedNetworkUrl != null
                  ? Image.network(
                      _resolvedNetworkUrl!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => _InitialsAvatar(name: name, radius: radius),
                    )
                  : _InitialsAvatar(name: name, radius: radius),
            ),
            if (verified)
              Positioned(
                right: -2,
                bottom: -2,
                child: VerifiedBadge(size: radius * 0.45),
              ),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.radius});

  final String name;
  final double radius;

  static String initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (trimmed.length >= 2) return trimmed.substring(0, 2).toUpperCase();
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AvatarGenerator.backgroundColor(name);
    final fg = AvatarGenerator.pixelColor(name);

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        initials(name),
        style: TextStyle(
          color: fg,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
