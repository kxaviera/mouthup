import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/feature_flags.dart';
import '../models/post.dart';
import '../models/profile_review.dart';
import '../models/service_catalog_item.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/display_name.dart';
import '../utils/post_share.dart';
import '../utils/profile_labels.dart';
import '../utils/user_profile_nav.dart';
import 'post_tile.dart';
import 'profile_reviews_section.dart';
import 'service_catalog_card.dart';
import 'user_avatar.dart';
import 'verified_badge.dart';

class SocialProfileBody extends StatefulWidget {
  const SocialProfileBody({
    super.key,
    required this.app,
    required this.username,
    required this.isSelf,
    this.onFollow,
    this.followLoading = false,
    this.onMessage,
    this.onEditPhoto,
  });

  final AppState app;
  final String username;
  final bool isSelf;
  final VoidCallback? onFollow;
  final bool followLoading;
  final VoidCallback? onMessage;
  final VoidCallback? onEditPhoto;

  @override
  State<SocialProfileBody> createState() => _SocialProfileBodyState();
}

class _SocialProfileBodyState extends State<SocialProfileBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get _tabCount => servicesMarketplaceEnabled ? 3 : 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    if (servicesMarketplaceEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.app.loadUserServices(widget.username);
      });
    }
  }

  @override
  void didUpdateWidget(covariant SocialProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tabController.length != _tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: _tabCount, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final username = widget.username;
    final isSelf = widget.isSelf;
    final info = app.profileInfoForUser(username);
    final social = app.socialProfile(username);
    final posts = app.postsByUser(username);
    final reviews = app.reviewsForUser(username);
    final services = app.servicesForUser(username);
    final following = app.isFollowing(username);

    final avatarUrl = isSelf ? (app.profileAvatarUrl ?? info.avatarUrl) : info.avatarUrl;
    final bio = isSelf ? (app.profileBio ?? info.bio) : info.bio;
    final verified = isSelf ? app.userVerified : info.verified;
    final followers = isSelf ? app.followerCount : (social?.followerCount ?? info.followerCount);
    final followingCount = isSelf ? app.followingCount : (social?.followingCount ?? info.followingCount);
    final subtitle = profileSubtitle(accountType: info.accountType, profession: info.profession, city: info.city);

    final display = isSelf ? app.displayName : app.displayNameForUser(username);
    final handle = usernameHandle(username);

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      UserAvatar(name: display, imageUrl: avatarUrl, verified: verified, radius: 40),
                      if (isSelf && widget.onEditPhoto != null)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: GestureDetector(
                            onTap: widget.onEditPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.bgCard, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: AppColors.onPrimary),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                UsernameWithBadge(
                  username: display,
                  verified: verified,
                  style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(handle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                if (verified) ...[
                  const SizedBox(height: 8),
                  const VerifiedProfileChip(),
                ],
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.text, fontSize: 14, height: 1.4),
                    ),
                  ],
                  if (reviews.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _RatingSummary(reviews: reviews),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _statTile('${posts.length}', 'Listings')),
                      Container(width: 1, height: 36, color: AppColors.border),
                      Expanded(
                        child: _statTile(
                          '$followers',
                          'Followers',
                          onTap: () => context.push('/profile/connections?user=$username&type=followers'),
                        ),
                      ),
                      Container(width: 1, height: 36, color: AppColors.border),
                      Expanded(
                        child: _statTile(
                          '$followingCount',
                          'Following',
                          onTap: () => context.push('/profile/connections?user=$username&type=following'),
                        ),
                      ),
                    ],
                  ),
                  if (!isSelf) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.followLoading ? null : widget.onFollow,
                            style: FilledButton.styleFrom(
                              backgroundColor: following ? AppColors.bgElevated : AppColors.primary,
                              foregroundColor: following ? AppColors.text : AppColors.onPrimary,
                              side: following ? const BorderSide(color: AppColors.border) : null,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: widget.followLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
                                  )
                                : Text(following ? 'Following' : 'Follow', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        if (widget.onMessage != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onMessage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.text,
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarHeader(
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.text,
              unselectedLabelColor: AppColors.textDim,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: [
                Tab(text: 'Posts (${posts.length})'),
                if (servicesMarketplaceEnabled) Tab(text: 'Services (${services.length})'),
                Tab(text: 'Reviews (${reviews.length})'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostsTab(app: app, username: username, posts: posts, isSelf: isSelf),
          if (servicesMarketplaceEnabled)
            _ServicesTab(app: app, username: username, services: services, isSelf: isSelf),
          _ReviewsTab(reviews: reviews),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label, {VoidCallback? onTap}) {
    final child = Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }
}

class _TabBarHeader extends SliverPersistentHeaderDelegate {
  _TabBarHeader(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bg,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) => false;
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.app, required this.username, required this.posts, required this.isSelf});

  final AppState app;
  final String username;
  final List<MouthUpPost> posts;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No listings yet', style: TextStyle(color: AppColors.textMuted))),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final post = posts[i];
              final profile = app.socialProfile(post.author);
              return PostTile(
                post: post,
                authorAvatarUrl: profile?.avatarUrl,
                authorVerified: post.authorIsVerified || (profile?.verified ?? false),
                showDivider: i < posts.length - 1,
                onTap: () => context.push('/post/${post.id}'),
                onSave: () => app.toggleSavePost(post.id),
                onComment: () => context.push('/post/${post.id}'),
                onShare: () => sharePost(context, post),
                onLike: () => app.toggleLikePost(post.id),
                onChat: isSelf || post.author == app.nickname
                    ? null
                    : () => openDirectChat(context, app, post.author, postId: post.id),
                onAuthorTap: () => openUserProfile(context, app, post.author),
              );
            },
            childCount: posts.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({
    required this.app,
    required this.username,
    required this.services,
    required this.isSelf,
  });

  final AppState app;
  final String username;
  final List<ServiceCatalogItem> services;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final canManage = isSelf && app.isServiceProvider;

    if (services.isEmpty) {
      return CustomScrollView(
        slivers: [
          if (canManage)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final saved = await context.push<bool>('/services/add');
                    if (saved == true && context.mounted) {
                      app.invalidateUserServices(username);
                      await app.loadUserServices(username);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add to catalog'),
                ),
              ),
            ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No services listed yet', style: TextStyle(color: AppColors.textMuted))),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        if (canManage)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final saved = await context.push<bool>('/services/add');
                  if (saved == true && context.mounted) {
                    app.invalidateUserServices(username);
                    await app.loadUserServices(username);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add to catalog'),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final item = services[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: i < services.length - 1 ? 10 : 0),
                  child: ServiceCatalogCard(
                    item: item,
                    compact: true,
                    onTap: canManage
                        ? () async {
                            final saved = await context.push<bool>(
                              '/services/${item.id}/edit',
                              extra: item,
                            );
                            if (saved == true && context.mounted) {
                              app.invalidateUserServices(username);
                              await app.loadUserServices(username);
                            }
                          }
                        : null,
                  ),
                );
              },
              childCount: services.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.reviews});

  final List<ProfileReview> reviews;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: ProfileReviewsSection(reviews: reviews)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.reviews});

  final List<ProfileReview> reviews;

  @override
  Widget build(BuildContext context) {
    final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: i < avg.round() ? const Color(0xFFFFC107) : AppColors.textDim,
          );
        }),
        const SizedBox(width: 6),
        Text(
          '${avg.toStringAsFixed(1)} · ${reviews.length} reviews',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
