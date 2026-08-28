import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';
import '../constants/chat_media.dart';
import '../constants/demo_account.dart';
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
import '../utils/hashtags.dart';
import '../utils/post_text.dart';

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

  bool get firebaseAuthAvailable => FirebaseAuthService.isAvailable;

  String nickname = '';
  bool usernameLocked = false;
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
  String? lastError;

  List<String> _trendingHashtags = [];
  List<DmConversation> _apiConversations = [];
  final Map<String, List<Uint8List>> _postImages = {};
  final Map<String, List<Uint8List>> _postVideos = {};
  Map<String, List<DirectMessage>> _dmThreads = {};
  final Map<String, int> _dmUnread = {};
  final Set<String> _takenUsernames = {};
  final _random = Random();

  int get unreadNotificationCount => notifications.where((n) => !n.read).length;

  List<String> get trendingHashtags =>
      _trendingHashtags.isNotEmpty ? _trendingHashtags : topTrendingHashtags(posts.map((p) => p.content));

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
    usernameLocked = user.usernameLocked;
    emailVerified = user.emailVerified;
    onboardingDone = user.onboardingDone;
    isLoggedIn = true;
    if (nickname.isNotEmpty) _takenUsernames.add(nickname);
  }

  Future<void> _hydrateSession() async {
    final me = await _api.getMe();
    _applyUser(me);
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
    await _connectRealtime();
  }

  bool get realtimeConnected => _realtime.isConnected;

  void joinDmPeer(String peer) => _realtime.joinDm(peer);

  Future<void> _connectRealtime() async {
    if (!isLoggedIn) return;
    final token = await _api.getAccessToken();
    if (token == null || token.isEmpty) return;

    if (!_realtimeHandlersRegistered) {
      _realtimeHandlersRegistered = true;
      _realtime.on('dm:new', _onDmNew);
      _realtime.on('notification:new', _onNotificationNew);
    }

    _realtime.connect(token);
    await _push.init(_api.registerFcmToken);
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

  void _disconnectRealtime() {
    _realtime.disconnect();
  }

  Future<void> refreshFeed({String? hashtag}) async {
    if (!isLoggedIn) return;
    loading = true;
    notifyListeners();
    try {
      posts = await _api.fetchFeed(hashtag: hashtag);
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
    if (!isLoggedIn) return;
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
    if (!isLoggedIn) return;
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
    try {
      await _api.blockUser(name);
      await refreshBlocked();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> unblockUser(String name) async {
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
    _applyUser(auth.user);
    await Future.wait([
      refreshFeed(),
      refreshBlocked(),
      refreshNotifications(),
      loadDmThreads(),
    ]);
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
    final loginEmail = (emailInput ?? email).trim().toLowerCase();
    if (loginEmail.isEmpty) return 'Enter your email';
    if (password == null || password.isEmpty) return 'Enter your password';

    loading = true;
    notifyListeners();
    try {
      AuthResult auth;
      if (firebaseAuthAvailable) {
        final cred = await _firebaseAuth.signInWithEmail(loginEmail, password);
        final idToken = await cred.user!.getIdToken();
        if (idToken == null) return 'Could not get Firebase token';
        auth = await _api.loginWithFirebase(idToken);
      } else {
        auth = await _api.login(loginEmail, password);
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

  Future<String?> loginAsDemo() => login(
        emailInput: DemoAccount.email,
        password: DemoAccount.password,
      );

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
    if (nickname.isEmpty) return 'Username required';
    try {
      final user = await _api.assignUsername(nickname);
      nickname = user.username ?? nickname;
      usernameLocked = user.usernameLocked;
      onboardingDone = user.onboardingDone;
      _takenUsernames.add(nickname);
      await refreshFeed();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
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
    isLoggedIn = false;
    emailVerified = false;
    onboardingDone = false;
    email = '';
    nickname = '';
    usernameLocked = false;
    posts = [];
    comments = [];
    notifications = [];
    blockedUsers = const [];
    _trendingHashtags = [];
    _apiConversations = [];
    _dmThreads = {};
    _dmUnread.clear();
    _postImages.clear();
    _postVideos.clear();
    _takenUsernames.clear();
  }

  bool isPostAuthor(String postId) {
    final post = getPost(postId);
    return post?.author == nickname;
  }

  List<MouthUpPost> get myPosts => posts.where((p) => p.author == nickname).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<MouthUpPost> get savedPosts => posts.where((p) => p.userSaved).toList();

  int postDiscussionScore(String postId) => commentCount(postId);

  Future<ModerationResult?> addPost(
    MouthUpPost post, {
    List<Uint8List> images = const [],
    List<Uint8List> videos = const [],
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
      );
      _upsertPost(created);
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

  Future<void> toggleSavePost(String postId) async {
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
