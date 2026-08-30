import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';
import '../constants/account_types.dart';
import '../constants/chat_media.dart';
import '../constants/demo_account.dart';
import '../data/ui_preview_data.dart';
import '../constants/listing_types.dart';
import '../constants/moods.dart';
import '../models/app_notification.dart';
import '../models/chat_message.dart';
import '../models/direct_message.dart';
import '../models/post.dart';
import '../models/post_comment.dart';
import '../services/api/api_exception.dart';
import '../services/api/mouthup_api.dart';
import '../services/content_moderator.dart';
import '../services/firebase_auth_service.dart';
import '../services/push_service.dart';
import '../services/realtime_service.dart';
import '../services/feed_preferences_storage.dart';
import '../utils/feed_comfort.dart';
import '../models/profile_review.dart';
import '../models/review_request.dart';
import '../models/social_profile.dart';
import '../utils/hashtags.dart';
import '../utils/display_name.dart';
import '../utils/post_text.dart';

class UserProfileInfo {
  const UserProfileInfo({
    this.screenName,
    this.accountType,
    this.profession,
    this.city,
    this.avatarUrl,
    this.bio,
    this.verified = false,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  final String? screenName;
  final String? accountType;
  final String? profession;
  final String? city;
  final String? avatarUrl;
  final String? bio;
  final bool verified;
  final int followerCount;
  final int followingCount;
}

enum FeedTab { nearby, following }

enum ProfileVoteType { like, dislike }

class AppState extends ChangeNotifier {
  AppState({
    MouthUpApi? api,
    RealtimeService? realtime,
    PushService? push,
    FirebaseAuthService? firebaseAuth,
  })  : _api = api ?? MouthUpApi(),
        _realtime = realtime ?? RealtimeService(),
        _push = push ?? PushService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuthService();

  final MouthUpApi _api;
  final RealtimeService _realtime;
  final PushService _push;
  final FirebaseAuthService _firebaseAuth;
  bool _realtimeHandlersRegistered = false;
  bool _realtimeConnected = false;

  bool get firebaseAuthAvailable => FirebaseAuthService.isAvailable;

  String get displayName => displayNameFor(screenName: screenName, username: nickname);

  String displayNameForUser(String username) {
    if (username == nickname) return displayName;
    final social = _socialProfiles[username];
    if (social != null) {
      return displayNameFor(screenName: social.screenName, username: username);
    }
    for (final post in posts) {
      if (post.author == username) return post.displayAuthor;
    }
    return username;
  }

  String nickname = '';
  String screenName = '';
  bool usernameLocked = false;
  String? accountType;
  String? profession;
  String? userCity;
  int followerCount = 0;
  int followingCount = 0;
  bool userVerified = false;
  String? profileAvatarUrl;
  String? profileBio;
  String? feedListingFilter;
  String searchQuery = '';
  FeedTab feedTab = FeedTab.nearby;
  AccountTypeId? onboardingAccountType;
  String? onboardingProfession;
  String? onboardingCity;
  String email = '';
  bool isLoggedIn = false;
  bool emailVerified = false;
  bool onboardingDone = false;
  List<MouthUpPost> posts = [];
  List<PostComment> comments = [];
  List<AppNotification> notifications = [];
  List<BlockedUser> blockedUsers = const [];
  bool dailyReminderEnabled = true;
  bool pushNotificationsEnabled = true;
  bool ready = false;
  bool loading = false;
  bool previewMode = false;
  String? lastError;

  final FeedPreferencesStorage _feedPrefs = FeedPreferencesStorage();

  bool comfortFeedEnabled = false;
  Set<String> topicShields = {};
  List<String> _trendingHashtags = [];
  List<DmConversation> _apiConversations = [];
  final Map<String, List<Uint8List>> _postImages = {};
  final Map<String, List<Uint8List>> _postVideos = {};
  Map<String, List<DirectMessage>> _dmThreads = {};
  final Map<String, int> _dmUnread = {};
  final Set<String> _takenUsernames = {};
  final Set<String> _followingUsers = {};
  final Set<String> _followerUsers = {};
  final Map<String, SocialProfile> _socialProfiles = {};
  final Map<String, ProfileVoteType> _profileVotes = {};
  final List<ReviewRequest> _reviewRequests = [];
  List<SocialProfile> _suggestedProfiles = [];
  List<String> _storyUsernames = [];
  final _random = Random();

  int get unreadNotificationCount => notifications.where((n) => !n.read).length;

  List<String> get trendingHashtags =>
      _trendingHashtags.isNotEmpty ? _trendingHashtags : topTrendingHashtags(posts.map((p) => p.content));

  List<MouthUpPost> get displayPosts => applyFeedFilters(
        posts: posts,
        comfortMode: comfortFeedEnabled,
        topicShields: topicShields,
        viewerUsername: nickname.isEmpty ? null : nickname,
      );

  List<String> get storyUsernames => _storyUsernames;

  List<SocialProfile> get suggestedProfiles => _suggestedProfiles;

  SocialProfile? socialProfile(String username) {
    if (_socialProfiles.containsKey(username)) return _socialProfiles[username];
    for (final post in posts) {
      if (post.author == username) {
        return SocialProfile(
          username: username,
          avatarUrl: avatarUrlForUser(username),
          city: post.authorCity,
          accountType: post.authorAccountType,
          profession: post.authorProfession,
        );
      }
    }
    return null;
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  List<MouthUpPost> get searchResults {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return posts
        .where((p) =>
            p.content.toLowerCase().contains(q) ||
            (p.title?.toLowerCase().contains(q) ?? false) ||
            (p.location?.toLowerCase().contains(q) ?? false) ||
            p.author.toLowerCase().contains(q))
        .toList();
  }

  List<SocialProfile> get searchUserResults {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _socialProfiles.values
        .where((p) =>
            p.username.toLowerCase().contains(q) ||
            (p.city?.toLowerCase().contains(q) ?? false) ||
            (p.bio?.toLowerCase().contains(q) ?? false))
        .where((p) => p.username != nickname)
        .toList();
  }

  ProfileVoteType? myProfileVote(String username) => _profileVotes[username];

  int profileLikes(String username) => _socialProfiles[username]?.profileLikes ?? 0;

  int profileDislikes(String username) => _socialProfiles[username]?.profileDislikes ?? 0;

  Future<String?> voteProfile(String username, ProfileVoteType vote) async {
    if (isSelf(username)) return 'You cannot vote on your own profile';
    if (_profileVotes.containsKey(username)) return 'You already voted on this profile';
    _profileVotes[username] = vote;
    final existing = _socialProfiles[username];
    if (existing != null) {
      _socialProfiles[username] = SocialProfile(
        username: existing.username,
        screenName: existing.screenName,
        avatarUrl: existing.avatarUrl,
        bio: existing.bio,
        city: existing.city,
        accountType: existing.accountType,
        profession: existing.profession,
        verified: existing.verified,
        followerCount: existing.followerCount,
        followingCount: existing.followingCount,
        reviews: existing.reviews,
        mutualCount: existing.mutualCount,
        profileLikes: existing.profileLikes + (vote == ProfileVoteType.like ? 1 : 0),
        profileDislikes: existing.profileDislikes + (vote == ProfileVoteType.dislike ? 1 : 0),
      );
    }
    notifyListeners();
    return null;
  }

  void setFeedListingFilter(String? apiValue) {
    feedListingFilter = apiValue;
    notifyListeners();
  }

  void setFeedTab(FeedTab tab) {
    feedTab = tab;
    notifyListeners();
  }

  List<MouthUpPost> feedPostsForTab(FeedTab tab) {
    final sorted = [...posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    switch (tab) {
      case FeedTab.nearby:
        final city = userCity?.toLowerCase();
        if (city == null || city.isEmpty) return sorted;
        return sorted.where((p) {
          final loc = p.location?.toLowerCase() ?? '';
          final authorCity = p.authorCity?.toLowerCase() ?? '';
          return loc.contains(city) || authorCity.contains(city);
        }).toList();
      case FeedTab.following:
        return sorted
            .where((p) => p.author == nickname || _followingUsers.contains(p.author))
            .toList();
    }
  }

  List<MouthUpPost> get currentFeedPosts => feedPostsForTab(feedTab);

  void setProfileAvatarUrl(String url) {
    profileAvatarUrl = url;
    notifyListeners();
  }

  void setProfileBio(String bio) {
    profileBio = bio;
    notifyListeners();
  }

  Future<void> loadFeedPreferences() async {
    comfortFeedEnabled = await _feedPrefs.getComfortFeedEnabled();
    topicShields = await _feedPrefs.getTopicShields();
    notifyListeners();
  }

  Future<void> setComfortFeedEnabled(bool enabled, {Duration? duration}) async {
    comfortFeedEnabled = enabled;
    await _feedPrefs.setComfortFeedEnabled(enabled, duration: duration);
    notifyListeners();
  }

  Future<void> toggleTopicShield(String id, bool enabled) async {
    topicShields = {...topicShields};
    if (enabled) {
      topicShields.add(id);
    } else {
      topicShields.remove(id);
    }
    await _feedPrefs.setTopicShields(topicShields);
    notifyListeners();
  }

  Future<void> onPostedWithMood(MoodId? mood) async {
    if (triggersComfortMode(mood)) {
      await setComfortFeedEnabled(true, duration: const Duration(hours: 24));
    }
  }

  Future<void> initialize() async {
    try {
      if (await _api.hasSession()) {
        await _hydrateSession();
      }
    } catch (_) {
      await _api.clearSession();
      _resetLocalSession();
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  void _applyUser(SessionUser user) {
    email = user.email;
    nickname = user.username ?? nickname;
    screenName = user.screenName ?? screenName;
    usernameLocked = user.usernameLocked;
    emailVerified = user.emailVerified;
    onboardingDone = user.onboardingDone;
    accountType = user.accountType;
    profession = user.profession;
    userCity = user.city;
    followerCount = user.followerCount;
    followingCount = user.followingCount;
    userVerified = user.isVerified;
    isLoggedIn = true;
    if (nickname.isNotEmpty) _takenUsernames.add(nickname);
  }

  void setOnboardingAccountType(AccountTypeId id) {
    onboardingAccountType = id;
    notifyListeners();
  }

  void setOnboardingProfession(String value) {
    onboardingProfession = value;
    notifyListeners();
  }

  void setOnboardingCity(String value) {
    onboardingCity = value;
    notifyListeners();
  }

  Future<String?> saveUsername({String? username, String? screenNameInput}) async {
    final nextUsername = (username ?? nickname).trim();
    final nextScreenName = (screenNameInput ?? screenName).trim();
    if (nextUsername.isEmpty) return 'Username required';
    if (nextScreenName.isEmpty) return 'Screen name required';
    try {
      final user = await _api.assignUsername(nextUsername, nextScreenName);
      nickname = user.username ?? nextUsername;
      screenName = user.screenName ?? nextScreenName;
      usernameLocked = user.usernameLocked;
      _takenUsernames.add(nickname);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> _hydrateSession() async {
    final me = await _api.getMe();
    _applyUser(me);
    await loadFeedPreferences();
    await refreshFeed();
    try {
      await refreshBlocked();
    } catch (_) {}
    try {
      await refreshNotifications();
    } catch (_) {}
    try {
      await loadDmThreads();
    } catch (_) {}
    try {
      await refreshFollowingGraph();
    } catch (_) {}
    await _connectRealtime();
  }

  Future<void> refreshFollowingGraph() async {
    if (previewMode) return;
    final following = await _api.fetchFollowing();
    final followers = await _api.fetchFollowers();
    _followingUsers
      ..clear()
      ..addAll(following);
    _followerUsers
      ..clear()
      ..addAll(followers);
    notifyListeners();
  }

  Future<void> loadPublicProfile(String username) async {
    if (previewMode || isSelf(username)) return;
    try {
      final data = await _api.fetchPublicProfile(username);
      final name = data['username'] as String? ?? username;
      _socialProfiles[name] = SocialProfile(
        username: name,
        screenName: data['screenName'] as String?,
        avatarUrl: avatarUrlForUser(name),
        bio: null,
        city: data['city'] as String?,
        accountType: data['accountType'] as String?,
        profession: data['profession'] as String?,
        verified: data['isVerified'] as bool? ?? false,
        followerCount: data['followerCount'] as int? ?? 0,
        followingCount: data['followingCount'] as int? ?? 0,
      );
      if (data['isFollowing'] == true) {
        _followingUsers.add(name);
      }
      notifyListeners();
    } on ApiException catch (_) {}
  }

  bool get realtimeConnected => _realtimeConnected;

  void joinDmPeer(String peer) => _realtime.joinDm(peer);

  Future<void> _connectRealtime() async {
    if (!isLoggedIn) return;
    final token = await _api.getAccessToken();
    if (token == null || token.isEmpty) return;

    if (!_realtimeHandlersRegistered) {
      _realtimeHandlersRegistered = true;
      _realtime.on('connect', _onRealtimeConnect);
      _realtime.on('disconnect', _onRealtimeDisconnect);
      _realtime.on('dm:new', _onDmNew);
      _realtime.on('notification:new', _onNotificationNew);
      _realtime.on('feed:new', _onFeedNew);
      _realtime.on('feed:updated', _onFeedUpdated);
      _realtime.on('feed:removed', _onFeedRemoved);
      _realtime.on('profile:updated', _onProfileUpdated);
      _realtime.on('follow:new', _onFollowNew);
    }

    _realtime.connect(token);
    await _push.init(_api.registerFcmToken);
  }

  void _onRealtimeConnect(String event, dynamic data) {
    _realtimeConnected = true;
    if (userCity != null && userCity!.isNotEmpty) {
      _realtime.setCity(userCity);
    }
    notifyListeners();
  }

  void _onRealtimeDisconnect(String event, dynamic data) {
    _realtimeConnected = false;
    notifyListeners();
  }

  void _onDmNew(String event, dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final peer = (map['peer'] as String?) ?? (map['author'] as String?) ?? '';
    if (peer.isEmpty || peer == nickname) return;

    final msg = DirectMessage.fromJson(map, peer, nickname);
    final thread = <DirectMessage>[...(_dmThreads[peer] ?? const <DirectMessage>[])];
    if (thread.any((m) => m.id == msg.id)) return;
    thread.add(msg);
    _dmThreads[peer] = thread;
    _dmUnread[peer] = (_dmUnread[peer] ?? 0) + 1;
    notifyListeners();
  }

  void _onNotificationNew(String event, dynamic data) {
    refreshNotifications();
  }

  void _onFeedNew(String event, dynamic data) {
    if (previewMode || data is! Map) return;
    try {
      final post = MouthUpPost.fromJson(Map<String, dynamic>.from(data));
      if (isBlocked(post.author)) return;
      _upsertPost(post);
      notifyListeners();
    } catch (_) {}
  }

  void _onFeedUpdated(String event, dynamic data) {
    if (previewMode || data is! Map) return;
    try {
      final updated = MouthUpPost.fromJson(Map<String, dynamic>.from(data));
      posts = posts.map((p) => p.id == updated.id ? updated : p).toList();
      notifyListeners();
    } catch (_) {}
  }

  void _onFeedRemoved(String event, dynamic data) {
    if (previewMode || data is! Map) return;
    final id = data['id'] as String?;
    if (id == null) return;
    posts = posts.where((p) => p.id != id).toList();
    notifyListeners();
  }

  void _onProfileUpdated(String event, dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final username = map['username'] as String?;
    final verified = map['isVerified'] as bool?;
    final city = map['city'] as String?;
    final banned = map['banned'] as bool?;

    if (username != null && username == nickname) {
      if (verified != null) userVerified = verified;
      final nextScreen = map['screenName'] as String?;
      if (nextScreen != null) screenName = nextScreen;
      if (city != null) {
        userCity = city;
        _realtime.setCity(city);
      }
      if (banned == true) {
        logout();
        return;
      }
    }

    if (username != null) {
      final existing = _socialProfiles[username];
      if (existing != null) {
        _socialProfiles[username] = SocialProfile(
          username: existing.username,
          screenName: map['screenName'] as String? ?? existing.screenName,
          avatarUrl: existing.avatarUrl,
          bio: existing.bio,
          city: city ?? existing.city,
          accountType: map['accountType'] as String? ?? existing.accountType,
          profession: map['profession'] as String? ?? existing.profession,
          verified: verified ?? existing.verified,
          followerCount: existing.followerCount,
          followingCount: existing.followingCount,
          reviews: existing.reviews,
          mutualCount: existing.mutualCount,
          profileLikes: existing.profileLikes,
          profileDislikes: existing.profileDislikes,
        );
      }
    }

    notifyListeners();
  }

  void _onFollowNew(String event, dynamic data) {
    if (previewMode || data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (map['following'] != true) return;
    followerCount++;
    _updateProfileFollowers(nickname, 1);
    notifyListeners();
  }

  void _disconnectRealtime() {
    _realtimeConnected = false;
    _realtime.disconnect();
  }

  Future<void> refreshFeed({
    String? hashtag,
    String? q,
    String? listingType,
    String? city,
  }) async {
    if (previewMode) return;
    if (!isLoggedIn) return;
    loading = true;
    notifyListeners();
    try {
      posts = await _api.fetchFeed(
        hashtag: hashtag,
        q: q,
        listingType: listingType,
        city: city ?? userCity,
      );
      _trendingHashtags = await _api.fetchTrendingHashtags();
      lastError = null;
    } on ApiException catch (e) {
      lastError = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBlocked() async {
    if (!isLoggedIn) return;
    blockedUsers = await _api.getBlocked();
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    if (!isLoggedIn) return;
    try {
      notifications = await _api.fetchNotifications();
      lastError = null;
    } on ApiException catch (e) {
      lastError = e.message;
    }
    notifyListeners();
  }

  Future<void> loadPostDetail(String postId) async {
    if (!isLoggedIn) return;
    if (previewMode && getPost(postId) != null) return;
    try {
      final post = await _api.fetchPost(postId);
      _upsertPost(post);
      final postComments = await _api.fetchComments(postId);
      comments = [...comments.where((c) => c.postId != postId), ...postComments];
      notifyListeners();
    } on ApiException catch (e) {
      lastError = e.message;
      notifyListeners();
    }
  }

  Future<void> loadMyPosts() async {
    if (previewMode || !isLoggedIn) return;
    try {
      final mine = await _api.fetchMyPosts();
      for (final p in mine) {
        _upsertPost(p);
      }
      notifyListeners();
    } on ApiException catch (e) {
      lastError = e.message;
    }
  }

  Future<void> loadSavedPosts() async {
    if (previewMode || !isLoggedIn) return;
    try {
      final saved = await _api.fetchSavedPosts();
      for (final p in saved) {
        _upsertPost(p.copyWith(userSaved: true));
      }
      notifyListeners();
    } on ApiException catch (e) {
      lastError = e.message;
    }
  }

  void _upsertPost(MouthUpPost post) {
    posts = [post, ...posts.where((p) => p.id != post.id)];
  }

  void markNotificationRead(String id) {
    notifications = notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList();
    notifyListeners();
    _api.markNotificationRead(id).catchError((_) {});
  }

  void markAllNotificationsRead() {
    notifications = notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    _api.markAllNotificationsRead().catchError((_) {});
  }

  Future<void> setDailyReminder(bool value) async {
    dailyReminderEnabled = value;
    notifyListeners();
    if (isLoggedIn) {
      await _api.updatePreferences(dailyReminder: value);
    }
  }

  Future<void> setPushNotifications(bool value) async {
    pushNotificationsEnabled = value;
    notifyListeners();
    if (isLoggedIn) {
      await _api.updatePreferences(pushEnabled: value);
    }
  }

  Future<String?> blockUser(String name) async {
    if (previewMode) return 'Not available in preview mode';
    try {
      await _api.blockUser(name);
      await refreshBlocked();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> unblockUser(String name) async {
    if (previewMode) return 'Not available in preview mode';
    try {
      await _api.unblockUser(name);
      await refreshBlocked();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  bool isBlocked(String peer) => blockedUsers.any((u) => u.nickname == peer);

  bool isSelf(String user) => user == nickname;

  List<MouthUpPost> postsByUser(String user) {
    return posts.where((p) => p.author == user).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  UserProfileInfo profileInfoForUser(String user) {
    final social = socialProfile(user);
    if (social != null) {
      return UserProfileInfo(
        screenName: social.screenName,
        accountType: social.accountType,
        profession: social.profession,
        city: social.city,
        avatarUrl: social.avatarUrl,
        bio: social.bio,
        verified: social.verified,
        followerCount: social.followerCount,
        followingCount: social.followingCount,
      );
    }
    for (final post in posts) {
      if (post.author == user) {
        return UserProfileInfo(
          screenName: post.authorScreenName,
          accountType: post.authorAccountType,
          profession: post.authorProfession,
          city: post.authorCity,
          avatarUrl: avatarUrlForUser(user),
        );
      }
    }
    return UserProfileInfo(avatarUrl: avatarUrlForUser(user));
  }

  bool isFollowing(String username) => _followingUsers.contains(username);

  List<String> followingUsersFor(String username) {
    if (isSelf(username)) {
      return _followingUsers.toList()..sort();
    }
    return const [];
  }

  List<String> followerUsersFor(String username) {
    if (isSelf(username)) {
      return _followerUsers.toList()..sort();
    }
    final social = socialProfile(username);
    if (social != null && previewMode) {
      return uiPreviewFollowers().take(social.followerCount.clamp(0, 20)).toList();
    }
    return const [];
  }

  Future<void> toggleFollow(String username) async {
    if (previewMode) {
      if (_followingUsers.contains(username)) {
        _followingUsers.remove(username);
        followingCount = followingCount > 0 ? followingCount - 1 : 0;
        _updateProfileFollowers(username, 1, subtract: true);
      } else {
        _followingUsers.add(username);
        followingCount++;
        _updateProfileFollowers(username, 1);
      }
      notifyListeners();
      return;
    }
    try {
      if (_followingUsers.contains(username)) {
        await _api.unfollowUser(username);
        _followingUsers.remove(username);
        followingCount = followingCount > 0 ? followingCount - 1 : 0;
        _updateProfileFollowers(username, 1, subtract: true);
      } else {
        await _api.followUser(username);
        _followingUsers.add(username);
        followingCount++;
        _updateProfileFollowers(username, 1);
      }
      notifyListeners();
    } on ApiException catch (e) {
      lastError = e.message;
      notifyListeners();
    }
  }

  void _updateProfileFollowers(String username, int delta, {bool subtract = false}) {
    final existing = _socialProfiles[username];
    if (existing == null) return;
    _socialProfiles[username] = SocialProfile(
      username: existing.username,
      screenName: existing.screenName,
      avatarUrl: existing.avatarUrl,
      bio: existing.bio,
      city: existing.city,
      accountType: existing.accountType,
      profession: existing.profession,
      verified: existing.verified,
      followerCount: subtract
          ? (existing.followerCount - delta).clamp(0, 999999)
          : existing.followerCount + delta,
      followingCount: existing.followingCount,
      reviews: existing.reviews,
      mutualCount: existing.mutualCount,
      profileLikes: existing.profileLikes,
      profileDislikes: existing.profileDislikes,
    );
  }

  List<ProfileReview> reviewsForUser(String username) {
    return socialProfile(username)?.reviews ?? const [];
  }

  List<ReviewRequest> reviewRequestsInChat(String peer) {
    return _reviewRequests
        .where(
          (r) =>
              (r.requester == nickname && r.reviewer == peer) ||
              (r.reviewer == nickname && r.requester == peer),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<ReviewRequest> pendingReviewRequestsFrom(String peer) {
    return _reviewRequests
        .where((r) => r.reviewer == nickname && r.requester == peer && !r.completed)
        .toList();
  }

  bool hasOpenReviewRequest(String peer, String postId) {
    return _reviewRequests.any(
      (r) =>
          r.postId == postId &&
          !r.completed &&
          ((r.requester == nickname && r.reviewer == peer) ||
              (r.reviewer == nickname && r.requester == peer)),
    );
  }

  bool hasSubmittedReview(String profileUsername, String postId) {
    return reviewsForUser(profileUsername).any((r) => r.author == nickname && r.postId == postId);
  }

  Future<String?> requestReview(String peer, String postId) async {
    if (!canDm(peer)) return 'Cannot message this user';
    final post = getPost(postId);
    if (post == null) return 'Listing not found';
    if (hasOpenReviewRequest(peer, postId)) return 'Review already requested for this listing';
    if (hasSubmittedReview(peer, postId)) return 'You already reviewed this deal';

    _reviewRequests.add(
      ReviewRequest(
        id: 'rr-${DateTime.now().millisecondsSinceEpoch}',
        requester: nickname,
        reviewer: peer,
        postId: postId,
        createdAt: DateTime.now(),
      ),
    );
    await _appendDmSystemNote(
      peer,
      '📝 You requested a review from $peer for "${post.displayTitle}"',
    );
    notifyListeners();
    return null;
  }

  Future<String?> submitReview({
    required String profileUsername,
    required String postId,
    required int rating,
    required String text,
  }) async {
    if (isSelf(profileUsername)) return 'Cannot review yourself';
    if (rating < 1 || rating > 5) return 'Pick a star rating';
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Write a short review';
    if (hasSubmittedReview(profileUsername, postId)) return 'You already reviewed this deal';

    final post = getPost(postId);
    final review = ProfileReview(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      author: nickname,
      rating: rating,
      text: trimmed,
      createdAt: DateTime.now(),
      authorAvatarUrl: profileAvatarUrl ?? avatarUrlForUser(nickname),
      postId: postId,
      postTitle: post?.displayTitle,
    );
    _addReviewToProfile(profileUsername, review);

    for (var i = 0; i < _reviewRequests.length; i++) {
      final r = _reviewRequests[i];
      if (r.reviewer == nickname && r.requester == profileUsername && r.postId == postId && !r.completed) {
        _reviewRequests[i] = r.copyWith(completed: true);
      }
    }

    await _appendDmSystemNote(profileUsername, '⭐ You left a review for $profileUsername');
    notifyListeners();
    return null;
  }

  void _addReviewToProfile(String username, ProfileReview review) {
    final existing = _socialProfiles[username];
    if (existing == null) return;
    _socialProfiles[username] = SocialProfile(
      username: existing.username,
      screenName: existing.screenName,
      avatarUrl: existing.avatarUrl,
      bio: existing.bio,
      city: existing.city,
      accountType: existing.accountType,
      profession: existing.profession,
      verified: existing.verified,
      followerCount: existing.followerCount,
      followingCount: existing.followingCount,
      reviews: [...existing.reviews, review],
      mutualCount: existing.mutualCount,
      profileLikes: existing.profileLikes,
      profileDislikes: existing.profileDislikes,
    );
  }

  Future<void> _appendDmSystemNote(String peer, String text) async {
    if (previewMode) {
      final msg = DirectMessage(
        id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
        from: nickname,
        to: peer,
        text: text,
        createdAt: DateTime.now(),
        type: ChatMessageType.system,
      );
      _dmThreads[peer] = [...(_dmThreads[peer] ?? const []), msg];
      return;
    }
    await _sendDirect(peer, text, type: ChatMessageType.system);
  }

  bool canViewProfile(String user) => !isBlocked(user);

  Future<void> loadDmThreads() async {
    if (!isLoggedIn) return;
    try {
      _apiConversations = await _api.fetchConversations();
      for (final c in _apiConversations) {
        _dmUnread[c.peerNickname] = c.unread;
      }
      notifyListeners();
    } catch (_) {}
  }

  List<DirectMessage> dmMessages(String peer) {
    return List.unmodifiable(_dmThreads[peer] ?? const []);
  }

  Future<void> loadDmMessages(String peer) async {
    if (!isLoggedIn) return;
    try {
      final msgs = await _api.fetchMessages(peer, nickname);
      _dmThreads[peer] = msgs;
      _dmUnread[peer] = 0;
      notifyListeners();
    } on ApiException catch (e) {
      lastError = e.message;
    }
  }

  List<DmConversation> get dmConversations {
    if (_apiConversations.isNotEmpty) {
      return [..._apiConversations]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final list = <DmConversation>[];
    for (final entry in _dmThreads.entries) {
      final msgs = entry.value;
      if (msgs.isEmpty) continue;
      final last = msgs.last;
      list.add(
        DmConversation(
          peerNickname: entry.key,
          lastMessage: last.text,
          updatedAt: last.createdAt,
          unread: _dmUnread[entry.key] ?? 0,
        ),
      );
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  int get unreadDmCount => _dmUnread.values.fold(0, (sum, n) => sum + n);

  bool canDm(String peer) => peer != nickname && !isBlocked(peer);

  void markDmRead(String peer) {
    _dmUnread[peer] = 0;
    notifyListeners();
  }

  Future<ModerationResult?> sendDirectMessage(String peer, String text) =>
      _sendDirect(peer, text, type: ChatMessageType.text);

  Future<ModerationResult?> sendDirectEmoji(String peer, String emoji) =>
      _sendDirect(peer, emoji, type: ChatMessageType.emoji);

  Future<ModerationResult?> sendDirectGif(String peer, String url, {String label = ''}) =>
      _sendDirect(peer, label.isEmpty ? 'GIF' : label, type: ChatMessageType.gif, mediaUrl: url);

  Future<ModerationResult?> sendDirectSticker(String peer, ChatSticker sticker) => _sendDirect(
        peer,
        sticker.isEmoji ? sticker.emoji! : sticker.label,
        type: ChatMessageType.sticker,
        mediaUrl: sticker.imageUrl,
      );

  Future<ModerationResult?> _sendDirect(
    String peer,
    String text, {
    ChatMessageType type = ChatMessageType.text,
    String? mediaUrl,
  }) async {
    if (!canDm(peer)) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty && type == ChatMessageType.text) return null;

    if (type == ChatMessageType.text) {
      final mod = await ContentModerator.check(trimmed);
      if (!mod.allowed) return mod;
    }

    if (type == ChatMessageType.system && trimmed.isEmpty) return null;

    if (previewMode) {
      final msg = DirectMessage(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        from: nickname,
        to: peer,
        text: trimmed.isEmpty ? (mediaUrl ?? '') : trimmed,
        createdAt: DateTime.now(),
        type: type,
        mediaUrl: mediaUrl,
      );
      _dmThreads[peer] = [...(_dmThreads[peer] ?? const []), msg];
      notifyListeners();
      return null;
    }

    try {
      final apiType = switch (type) {
        ChatMessageType.text => 'TEXT',
        ChatMessageType.emoji => 'EMOJI',
        ChatMessageType.gif => 'GIF',
        ChatMessageType.sticker => 'STICKER',
        ChatMessageType.system => 'TEXT',
      };
      await _api.sendMessage(peer, trimmed, type: apiType);
      await loadDmMessages(peer);
      return null;
    } on ApiException catch (e) {
      return ModerationResult(allowed: false, userMessage: e.message);
    }
  }

  List<Uint8List> postImages(String postId) => _postImages[postId] ?? const [];

  void setPostImages(String postId, List<Uint8List> images) {
    if (images.isEmpty) {
      _postImages.remove(postId);
    } else {
      _postImages[postId] = images;
    }
    notifyListeners();
  }

  List<Uint8List> postVideos(String postId) => _postVideos[postId] ?? const [];

  void setPostVideos(String postId, List<Uint8List> videos) {
    if (videos.isEmpty) {
      _postVideos.remove(postId);
    } else {
      _postVideos[postId] = videos;
    }
    notifyListeners();
  }

  List<PostComment> commentsForPost(String postId) {
    return comments.where((c) => c.postId == postId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  int commentCount(String postId) => comments.where((c) => c.postId == postId).length;

  Future<ModerationResult?> addComment(String postId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final mod = await ContentModerator.check(trimmed);
    if (!mod.allowed) return mod;

    try {
      final raw = await _api.addComment(postId, trimmed);
      final comment = raw.postId.isEmpty
          ? PostComment(id: raw.id, postId: postId, author: raw.author, text: raw.text, createdAt: raw.createdAt)
          : raw;
      comments = [...comments, comment];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return ModerationResult(allowed: false, userMessage: e.message);
    }
  }

  bool isCommentAuthor(String commentId) {
    try {
      return comments.firstWhere((c) => c.id == commentId).author == nickname;
    } catch (_) {
      return false;
    }
  }

  Future<String?> deleteComment(String commentId) async {
    if (!isCommentAuthor(commentId)) return 'You can only delete your own replies';
    PostComment? comment;
    try {
      comment = comments.firstWhere((c) => c.id == commentId);
    } catch (_) {
      return 'Reply not found';
    }
    try {
      await _api.deleteComment(comment.postId, commentId);
      comments = comments.where((c) => c.id != commentId).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<ModerationResult?> updatePost(String postId, String content) async {
    if (!isPostAuthor(postId)) return null;
    final trimmed = clampToWordLimit(content.trim());
    if (trimmed.isEmpty) return null;

    final mod = await ContentModerator.check(trimmed);
    if (!mod.allowed) return mod;

    try {
      final updated = await _api.updatePost(postId, trimmed);
      _upsertPost(updated);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return ModerationResult(allowed: false, userMessage: e.message);
    }
  }

  Future<String?> deletePost(String postId) async {
    if (!isPostAuthor(postId)) return 'You can only delete your own posts';
    try {
      await _api.deletePost(postId);
      posts = posts.where((p) => p.id != postId).toList();
      comments = comments.where((c) => c.postId != postId).toList();
      _postImages.remove(postId);
      _postVideos.remove(postId);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> reportPost(String postId, {String reason = 'Inappropriate content'}) async {
    try {
      await _api.reportPost(postId, reason);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> reportComment(String commentId, {String reason = 'Inappropriate reply'}) async {
    try {
      await _api.reportComment(commentId, reason);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> reportUser(String username, {String reason = 'Inappropriate behavior'}) async {
    try {
      await _api.reportUser(username, reason);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  String generateUniqueUsername() {
    for (var i = 0; i < 200; i++) {
      final base = nicknames[_random.nextInt(nicknames.length)];
      final suffix = _random.nextInt(9000) + 100;
      final candidate = '$base$suffix';
      if (!_takenUsernames.contains(candidate)) {
        return candidate;
      }
    }
    return 'User${DateTime.now().millisecondsSinceEpoch}';
  }

  void assignUsername(String name) {
    if (usernameLocked && onboardingDone) return;
    nickname = name;
    _takenUsernames.add(name);
    notifyListeners();
  }

  Future<void> _completeAuthSession(AuthResult auth) async {
    await _api.saveSession(auth);
    try {
      final me = await _api.getMe();
      _applyUser(me);
    } catch (_) {
      _applyUser(auth.user);
    }
    await Future.wait([
      refreshFeed(),
      refreshBlocked(),
      refreshNotifications(),
      loadDmThreads(),
    ]);
    try {
      await refreshFollowingGraph();
    } catch (_) {}
    await _connectRealtime();
  }

  Future<String?> loginWithGoogle() async {
    if (!firebaseAuthAvailable) return 'Firebase is not configured';

    loading = true;
    notifyListeners();
    try {
      final cred = await _firebaseAuth.signInWithGoogle();
      if (cred == null) return null;
      final idToken = await cred.user!.getIdToken();
      if (idToken == null) return 'Could not get Firebase token';
      final auth = await _api.loginWithFirebase(idToken);
      await _completeAuthSession(auth);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> login({String? emailInput, String? password}) async {
    final loginId = (emailInput ?? email).trim();
    if (loginId.isEmpty) return 'Enter your email or username';
    if (password == null || password.isEmpty) return 'Enter your password';

    loading = true;
    notifyListeners();
    try {
      AuthResult auth;
      final isEmail = loginId.contains('@');
      if (firebaseAuthAvailable && isEmail) {
        final cred = await _firebaseAuth.signInWithEmail(loginId.toLowerCase(), password);
        final idToken = await cred.user!.getIdToken();
        if (idToken == null) return 'Could not get Firebase token';
        auth = await _api.loginWithFirebase(idToken);
      } else {
        auth = await _api.login(loginId, password);
      }
      await _completeAuthSession(auth);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> loginAsDemo() async {
    if (kIsWeb) {
      enterUiPreview();
      return null;
    }
    loading = true;
    notifyListeners();
    try {
      final auth = await _api.loginAsDemo();
      await _completeAuthSession(auth);
      return null;
    } on ApiException catch (e) {
      enterUiPreview();
      return null;
    } catch (_) {
      enterUiPreview();
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void enterUiPreview() {
    previewMode = true;
    isLoggedIn = true;
    emailVerified = true;
    onboardingDone = true;
    nickname = DemoAccount.username;
    screenName = 'Cool Breeze';
    usernameLocked = true;
    email = DemoAccount.email;
    accountType = 'BOTH';
    userCity = 'Mumbai';
    profession = null;
    profileBio = 'Buy & sell locally in Mumbai. Open to swaps and good deals 🤝';
    profileAvatarUrl = avatarUrlForUser(DemoAccount.username);
    userVerified = true;
    followerCount = 128;
    followingCount = 54;
    posts = uiPreviewPosts();
    _socialProfiles
      ..clear()
      ..addAll(uiPreviewProfiles());
    _suggestedProfiles = uiPreviewSuggestions();
    _storyUsernames = [DemoAccount.username, ...uiPreviewFollowing()];
    _followingUsers
      ..clear()
      ..addAll(uiPreviewFollowing());
    _followerUsers
      ..clear()
      ..addAll(uiPreviewFollowers());
    _trendingHashtags = ['#sale', '#rent', '#service', '#giveaway'];
    lastError = null;
    loading = false;
    notifyListeners();
  }

  Future<String?> signup({required String emailInput, required String password}) async {
    loading = true;
    notifyListeners();
    try {
      if (firebaseAuthAvailable) {
        final cred = await _firebaseAuth.registerWithEmail(emailInput.trim(), password);
        final idToken = await cred.user!.getIdToken();
        if (idToken == null) return 'Could not get Firebase token';
        final auth = await _api.loginWithFirebase(idToken);
        await _completeAuthSession(auth);
        return null;
      }
      await _api.register(emailInput.trim(), password);
      return await login(emailInput: emailInput, password: password);
    } on ApiException catch (e) {
      return e.message;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign up failed';
    } catch (e) {
      return e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> verifyEmail(String code) async {
    try {
      final user = await _api.verifyEmail(code.trim());
      emailVerified = user.emailVerified;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> resendVerificationCode() async {
    try {
      await _api.resendVerification();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> requestPasswordReset(String emailInput) async {
    try {
      await _api.forgotPassword(emailInput.trim());
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> resetPassword({required String email, required String code, required String newPassword}) async {
    try {
      await _api.resetPassword(email: email.trim(), code: code.trim(), newPassword: newPassword);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> completeOnboarding() async {
    if (onboardingAccountType == null) return 'Pick how you will use MouthUp';
    if (onboardingAccountType == AccountTypeId.serviceProvider && onboardingProfession == null) {
      return 'Pick your profession';
    }
    if (onboardingCity == null || onboardingCity!.trim().length < 2) {
      return 'Enter your city';
    }
    try {
      final opt = accountTypeOptions.firstWhere((o) => o.id == onboardingAccountType);
      final user = await _api.completeProfile(
        accountType: opt.apiValue,
        profession: onboardingAccountType == AccountTypeId.serviceProvider ? onboardingProfession : null,
        city: onboardingCity,
      );
      nickname = user.username ?? nickname;
      usernameLocked = user.usernameLocked;
      onboardingDone = user.onboardingDone;
      accountType = user.accountType;
      profession = user.profession;
      userCity = user.city;
      await refreshFeed();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  void logoutPreview() {
    _disconnectRealtime();
    _resetLocalSession();
    notifyListeners();
  }

  Future<void> logout() async {
    _disconnectRealtime();
    if (firebaseAuthAvailable) {
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
    }
    await _api.logout();
    _resetLocalSession();
    notifyListeners();
  }

  Future<String?> deleteAccount() async {
    try {
      await _api.deleteAccount();
      _disconnectRealtime();
      _resetLocalSession();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  void _resetLocalSession() {
    previewMode = false;
    isLoggedIn = false;
    emailVerified = false;
    onboardingDone = false;
    email = '';
    nickname = '';
    screenName = '';
    usernameLocked = false;
    accountType = null;
    profession = null;
    userCity = null;
    onboardingAccountType = null;
    onboardingProfession = null;
    onboardingCity = null;
    posts = [];
    comments = [];
    notifications = [];
    blockedUsers = const [];
    _trendingHashtags = [];
    _apiConversations = [];
    _dmThreads = {};
    _dmUnread.clear();
    _reviewRequests.clear();
    _followerUsers.clear();
    _postImages.clear();
    _postVideos.clear();
    _followingUsers.clear();
    _socialProfiles.clear();
    userVerified = false;
    followerCount = 0;
    followingCount = 0;
    profileBio = null;
    profileAvatarUrl = null;
    _suggestedProfiles = [];
    _storyUsernames = [];
  }

  bool isPostAuthor(String postId) {
    final post = getPost(postId);
    return post?.author == nickname;
  }

  List<MouthUpPost> get myPosts => posts.where((p) => p.author == nickname).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<MouthUpPost> get savedPosts => posts.where((p) => p.userSaved).toList();

  int postDiscussionScore(String postId) => commentCount(postId);

  Future<ModerationResult?> addListing({
    required String title,
    required String content,
    required ListingTypeOption listingType,
    double? price,
    RentPeriodId? rentPeriod,
    String? swapFor,
    String? location,
    List<Uint8List> images = const [],
    List<Uint8List> videos = const [],
  }) async {
    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();
    if (trimmedTitle.length < 3) {
      return ModerationResult(allowed: false, userMessage: 'Title is too short');
    }
    if (trimmedContent.isEmpty && images.isEmpty && videos.isEmpty) return null;

    final mod = await ContentModerator.check('$trimmedTitle\n$trimmedContent');
    if (!mod.allowed) return mod;

    try {
      final media = <Map<String, String>>[];
      for (var i = 0; i < images.length; i++) {
        final uploaded = await _api.uploadMedia(images[i], 'photo_$i.jpg');
        media.add(uploaded);
      }
      for (var i = 0; i < videos.length; i++) {
        final uploaded = await _api.uploadMedia(videos[i], 'video_$i.mp4');
        media.add(uploaded);
      }
      final created = await _api.createListing(
        title: trimmedTitle,
        content: trimmedContent.isEmpty ? trimmedTitle : trimmedContent,
        listingType: listingType.apiValue,
        price: price,
        rentPeriod: rentPeriodToApi(rentPeriod),
        swapFor: swapFor,
        location: location ?? userCity,
        media: media,
      );
      _upsertPost(created);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return ModerationResult(allowed: false, userMessage: e.message);
    }
  }

  Future<String?> toggleListingStatus(String postId) async {
    if (!isPostAuthor(postId)) return 'You can only update your own listings';
    final post = getPost(postId);
    if (post == null || !post.isListing) return 'Not a listing';
    final next = post.isOpen ? 'CLOSED' : 'OPEN';
    if (previewMode) {
      posts = posts.map((p) => p.id == postId ? p.copyWith(listingStatus: next) : p).toList();
      notifyListeners();
      return null;
    }
    try {
      final updated = await _api.updateListingStatus(postId, next);
      posts = posts.map((p) => p.id == postId ? updated : p).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> toggleLikePost(String postId) async {
    if (previewMode) {
      posts = posts
          .map(
            (p) => p.id == postId
                ? p.copyWith(
                    userLiked: !p.userLiked,
                    likeCount: (p.likeCount + (p.userLiked ? -1 : 1)).clamp(0, 999999),
                  )
                : p,
          )
          .toList();
      notifyListeners();
      return;
    }
    try {
      final liked = await _api.toggleLike(postId);
      posts = posts
          .map(
            (p) => p.id == postId
                ? p.copyWith(
                    userLiked: liked,
                    likeCount: (p.likeCount + (liked ? 1 : -1)).clamp(0, 999999),
                  )
                : p,
          )
          .toList();
      notifyListeners();
    } on ApiException catch (_) {}
  }

  Future<ModerationResult?> addPost(
    MouthUpPost post, {
    List<Uint8List> images = const [],
    List<Uint8List> videos = const [],
    MoodId? mood,
  }) async {
    final content = clampToWordLimit(post.content.trim());
    if (content.isEmpty && images.isEmpty && videos.isEmpty) return null;

    final mod = await ContentModerator.check(content.isEmpty ? 'Shared media' : content);
    if (!mod.allowed) return mod;

    try {
      final media = <Map<String, String>>[];
      for (var i = 0; i < images.length; i++) {
        final uploaded = await _api.uploadMedia(images[i], 'photo_$i.jpg');
        media.add(uploaded);
      }
      for (var i = 0; i < videos.length; i++) {
        final uploaded = await _api.uploadMedia(videos[i], 'video_$i.mp4');
        media.add(uploaded);
      }
      final created = await _api.createPost(
        content.isEmpty ? 'Shared media' : content,
        media: media,
        mood: mood != null ? moodToApi(mood) : null,
      );
      _upsertPost(created);
      await onPostedWithMood(mood);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return ModerationResult(allowed: false, userMessage: e.message);
    }
  }

  MouthUpPost? getPost(String id) {
    try {
      return posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleSupportReaction(String postId, SupportReactionType type) async {
    try {
      final reaction = await _api.toggleSupportReaction(postId, type);
      posts = posts
          .map(
            (p) => p.id == postId
                ? p.copyWith(userSupportReaction: reaction, clearSupportReaction: reaction == null)
                : p,
          )
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      lastError = e.message;
      notifyListeners();
    }
  }

  Future<void> toggleSavePost(String postId) async {
    if (previewMode) {
      posts = posts
          .map((p) => p.id == postId ? p.copyWith(userSaved: !p.userSaved) : p)
          .toList();
      notifyListeners();
      return;
    }
    try {
      final saved = await _api.toggleSave(postId);
      posts = posts.map((p) => p.id == postId ? p.copyWith(userSaved: saved) : p).toList();
      notifyListeners();
    } on ApiException catch (e) {
      lastError = e.message;
      notifyListeners();
    }
  }
}
