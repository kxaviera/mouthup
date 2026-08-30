import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/social_profile.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/user_profile_nav.dart';
import 'user_avatar.dart';
import 'verified_badge.dart';

class FeedSuggestionCard extends StatelessWidget {
  const FeedSuggestionCard({super.key, required this.suggestions});

  final List<SocialProfile> suggestions;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Suggested for you',
                    style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  'Based on your area & interests',
                  style: TextStyle(color: AppColors.textDim.withValues(alpha: 0.9), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _SuggestionTile(profile: suggestions[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.profile});

  final SocialProfile profile;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final following = app.isFollowing(profile.username);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          UserAvatar(
            name: profile.username,
            imageUrl: profile.avatarUrl,
            verified: profile.verified,
            radius: 28,
            onTap: () => openUserProfile(context, app, profile.username),
          ),
          const SizedBox(height: 10),
          UsernameWithBadge(
            username: profile.username,
            verified: profile.verified,
            style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700),
            badgeSize: 14,
          ),
          const SizedBox(height: 4),
          Text(
            profile.bio ?? profile.city ?? 'Local member',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
          ),
          if (profile.mutualCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${profile.mutualCount} mutual',
              style: const TextStyle(color: AppColors.textDim, fontSize: 10),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => app.toggleFollow(profile.username),
              style: FilledButton.styleFrom(
                backgroundColor: following ? AppColors.bgElevated : AppColors.primary,
                foregroundColor: following ? AppColors.text : AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                following ? 'Following' : 'Follow',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
