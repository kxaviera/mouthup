import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/display_name.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_share.dart';
import '../../utils/user_profile_nav.dart';
import '../../widgets/post_tile.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.inTabShell = false});

  final bool inTabShell;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final query = app.searchQuery.trim();
    final results = app.searchResults;
    final users = app.searchUserResults;

    return ScreenWrapper(
      padding: false,
      bottomSafe: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: const Text(
              'Search',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: widget.inTabShell,
              textInputAction: TextInputAction.search,
              onChanged: app.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search listings or people…',
                prefixIcon: const Icon(Icons.search, color: AppColors.textDim),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textDim, size: 20),
                        onPressed: () {
                          _controller.clear();
                          app.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ),
          if (query.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Search by keyword or profile name', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else if (app.searchLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  if (users.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text('PEOPLE', style: TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    ),
                    ...users.map((u) {
                      final name = displayNameFor(screenName: u.screenName, username: u.username);
                      return ListTile(
                        leading: UserAvatar(name: name, imageUrl: u.avatarUrl, verified: u.verified, radius: 20),
                        title: Text(name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          u.username == name ? (u.city ?? '') : '@${u.username}${u.city != null ? ' · ${u.city}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        onTap: () => openUserProfile(context, app, u.username),
                      );
                    }),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'LISTINGS (${results.length})',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                  ),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No results', style: TextStyle(color: AppColors.textMuted))),
                    )
                  else
                    ...results.asMap().entries.map((e) {
                      final post = e.value;
                      final profile = app.socialProfile(post.author);
                      return PostTile(
                        post: post,
                        authorAvatarUrl: profile?.avatarUrl,
                        authorVerified: post.authorIsVerified || (profile?.verified ?? false),
                        showDivider: e.key < results.length - 1,
                        onTap: () => context.push('/post/${post.id}'),
                        onSave: () async {
                          final wasSaved = post.userSaved;
                          await app.toggleSavePost(post.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(wasSaved ? 'Removed from saved' : 'Post saved')),
                          );
                        },
                        onComment: () => context.push('/post/${post.id}'),
                        onShare: () => sharePost(context, post),
                        onLike: () => app.toggleLikePost(post.id),
                        onChat: post.author == app.nickname
                            ? null
                            : () => openDirectChat(context, app, post.author, postId: post.id),
                        onAuthorTap: () => openUserProfile(context, app, post.author),
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
