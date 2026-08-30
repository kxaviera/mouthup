import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../models/app_notification.dart';
import '../../models/direct_message.dart';
import '../../models/post.dart';
import '../../models/post_comment.dart';
import '../token_storage.dart';
import 'api_exception.dart';

class SessionUser {
  SessionUser({
    required this.id,
    required this.email,
    this.username,
    this.screenName,
    required this.emailVerified,
    required this.onboardingDone,
    this.usernameLocked = false,
    this.accountType,
    this.profession,
    this.city,
    this.followerCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
  });

  final String id;
  final String email;
  final String? username;
  final String? screenName;
  final bool emailVerified;
  final bool onboardingDone;
  final bool usernameLocked;
  final String? accountType;
  final String? profession;
  final String? city;
  final int followerCount;
  final int followingCount;
  final bool isVerified;

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        username: json['username'] as String?,
        screenName: json['screenName'] as String?,
        emailVerified: json['emailVerified'] as bool? ?? false,
        onboardingDone: json['onboardingDone'] as bool? ?? false,
        usernameLocked: json['usernameLocked'] as bool? ?? false,
        accountType: json['accountType'] as String?,
        profession: json['profession'] as String?,
        city: json['city'] as String?,
        followerCount: json['followerCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
        isVerified: json['isVerified'] as bool? ?? false,
      );
}

class AuthResult {
  AuthResult({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final SessionUser user;
}

class MouthUpApi {
  MouthUpApi({TokenStorage? storage}) : _storage = storage ?? TokenStorage() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!options.path.contains('/auth/login') &&
            !options.path.contains('/auth/demo') &&
            !options.path.contains('/auth/register') &&
            !options.path.contains('/auth/firebase') &&
            !options.path.contains('/auth/refresh')) {
          final token = await _storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        if (response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/') &&
            !error.requestOptions.extra.containsKey('retried')) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final opts = error.requestOptions;
            opts.extra['retried'] = true;
            final token = await _storage.getAccessToken();
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final res = await _dio.fetch(opts);
              handler.resolve(res);
              return;
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    ));
  }

  late final Dio _dio;
  final TokenStorage _storage;

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post('/auth/refresh', data: {'refreshToken': refresh});
      final data = res.data as Map<String, dynamic>;
      await _storage.saveTokens(accessToken: data['accessToken'] as String, refreshToken: data['refreshToken'] as String);
      return true;
    } catch (_) {
      await _storage.clear();
      return false;
    }
  }

  Future<T> _get<T>(String path, T Function(dynamic) parse) async {
    try {
      final res = await _dio.get(path);
      return parse(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> _post<T>(String path, Map<String, dynamic>? body, T Function(dynamic) parse) async {
    try {
      final res = await _dio.post(path, data: body);
      return parse(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> _patch<T>(String path, Map<String, dynamic>? body, T Function(dynamic) parse) async {
    try {
      final res = await _dio.patch(path, data: body);
      return parse(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> _delete<T>(String path, T Function(dynamic) parse) async {
    try {
      final res = await _dio.delete(path);
      return parse(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      if (msg is List) return ApiException(msg.join(', '), statusCode: e.response?.statusCode);
      return ApiException(msg.toString(), statusCode: e.response?.statusCode);
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        ApiConfig.isProduction
            ? 'Cannot reach server. Check your connection.'
            : 'Cannot reach server at ${ApiConfig.baseUrl}',
      );
    }
    return ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
  }

  Future<void> saveSession(AuthResult auth) {
    return _storage.saveTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken);
  }

  Future<void> clearSession() => _storage.clear();

  Future<bool> hasSession() async {
    final t = await _storage.getAccessToken();
    return t != null && t.isNotEmpty;
  }

  // — Auth —

  Future<AuthResult> loginAsDemo() async {
    return _post('/auth/demo', {}, (data) {
      final map = data as Map<String, dynamic>;
      return AuthResult(
        accessToken: map['accessToken'] as String,
        refreshToken: map['refreshToken'] as String,
        user: SessionUser.fromJson(map['user'] as Map<String, dynamic>),
      );
    });
  }

  Future<AuthResult> login(String login, String password) async {
    return _post('/auth/login', {'login': login, 'password': password}, (data) {
      final map = data as Map<String, dynamic>;
      return AuthResult(
        accessToken: map['accessToken'] as String,
        refreshToken: map['refreshToken'] as String,
        user: SessionUser.fromJson(map['user'] as Map<String, dynamic>),
      );
    });
  }

  Future<AuthResult> loginWithFirebase(String idToken) async {
    return _post('/auth/firebase', {'idToken': idToken}, (data) {
      final map = data as Map<String, dynamic>;
      return AuthResult(
        accessToken: map['accessToken'] as String,
        refreshToken: map['refreshToken'] as String,
        user: SessionUser.fromJson(map['user'] as Map<String, dynamic>),
      );
    });
  }

  Future<String?> register(String email, String password) async {
    return _post('/auth/register', {'email': email, 'password': password}, (data) {
      final map = data as Map<String, dynamic>;
      return map['devCode'] as String?;
    });
  }

  Future<SessionUser> verifyEmail(String code) async {
    return _post('/auth/verify-email', {'code': code}, (data) {
      final user = (data as Map<String, dynamic>)['user'] as Map<String, dynamic>;
      return SessionUser.fromJson(user);
    });
  }

  Future<String?> resendVerification() async {
    return _post('/auth/resend-verification', {}, (data) {
      return (data as Map<String, dynamic>)['devCode'] as String?;
    });
  }

  Future<String?> forgotPassword(String email) async {
    return _post('/auth/forgot-password', {'email': email}, (data) {
      return (data as Map<String, dynamic>)['devCode'] as String?;
    });
  }

  Future<void> resetPassword({required String email, required String code, required String newPassword}) {
    return _post('/auth/reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    }, (_) {});
  }

  Future<void> logout() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refresh});
      } catch (_) {}
    }
    await _storage.clear();
  }

  Future<void> deleteAccount() => _delete('/auth/account', (_) {});

  // — Users —

  Future<SessionUser> getMe() async {
    return _get('/users/me', (data) => SessionUser.fromJson(data as Map<String, dynamic>));
  }

  Future<SessionUser> assignUsername(String username, String screenName) async {
    return _post('/users/username', {'username': username, 'screenName': screenName}, (data) {
      return SessionUser.fromJson(data as Map<String, dynamic>);
    });
  }

  Future<SessionUser> updateScreenName(String screenName) async {
    return _patch('/users/screen-name', {'screenName': screenName}, (data) {
      return SessionUser.fromJson(data as Map<String, dynamic>);
    });
  }

  Future<SessionUser> completeProfile({
    required String accountType,
    String? profession,
    String? city,
  }) async {
    return _post('/users/onboarding/complete', {
      'accountType': accountType,
      if (profession != null) 'profession': profession,
      if (city != null) 'city': city,
    }, (data) => SessionUser.fromJson(data as Map<String, dynamic>));
  }

  Future<void> followUser(String username) => _post('/users/$username/follow', {}, (_) {});

  Future<void> unfollowUser(String username) => _delete('/users/$username/follow', (_) {});

  Future<List<String>> fetchFollowing() async {
    return _get('/users/me/following', (data) {
      return (data as List).map((e) => e as String).toList();
    });
  }

  Future<List<String>> fetchFollowers() async {
    return _get('/users/me/followers', (data) {
      return (data as List).map((e) => e as String).toList();
    });
  }

  Future<Map<String, dynamic>> fetchPublicProfile(String username) async {
    return _get('/users/$username', (data) => Map<String, dynamic>.from(data as Map));
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    return _get('/users/search?q=${Uri.encodeComponent(query.trim())}', (data) {
      return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<List<BlockedUser>> getBlocked() async {
    return _get('/users/blocked', (data) {
      return (data as List)
          .map((e) => BlockedUser(nickname: (e as Map)['nickname'] as String))
          .toList();
    });
  }

  Future<void> blockUser(String username) =>
      _post('/users/$username/block', {}, (_) {});

  Future<void> unblockUser(String username) =>
      _delete('/users/$username/block', (_) {});

  Future<void> updatePreferences({bool? pushEnabled, bool? dailyReminder}) {
    return _patch('/users/preferences', {
      if (pushEnabled != null) 'pushEnabled': pushEnabled,
      if (dailyReminder != null) 'dailyReminder': dailyReminder,
    }, (_) {});
  }

  Future<String?> getAccessToken() => _storage.getAccessToken();

  Future<void> registerFcmToken(String token) =>
      _patch('/users/fcm-token', {'token': token}, (_) {});

  // — Posts —

  Future<List<MouthUpPost>> fetchFeed({
    String? hashtag,
    String? q,
    String? listingType,
    String? city,
  }) async {
    final params = <String, String>{};
    if (hashtag != null) params['hashtag'] = hashtag.replaceFirst('#', '');
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (listingType != null) params['listingType'] = listingType;
    if (city != null && city.isNotEmpty) params['city'] = city;
    final query = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    return _get('/posts$query', (data) {
      final items = (data as Map<String, dynamic>)['items'] as List;
      return items.map((e) => MouthUpPost.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<String>> fetchTrendingHashtags() async {
    return _get('/posts/trending-hashtags', (data) {
      return (data as List).map((e) => '#${(e as Map)['tag']}').toList();
    });
  }

  Future<MouthUpPost> fetchPost(String id) async {
    return _get('/posts/$id', (data) => MouthUpPost.fromJson(data as Map<String, dynamic>));
  }

  Future<MouthUpPost> createListing({
    required String title,
    required String content,
    required String listingType,
    double? price,
    String? currency,
    String? rentPeriod,
    String? swapFor,
    String? location,
    List<Map<String, String>> media = const [],
  }) async {
    return _post('/posts', {
      'title': title,
      'content': content,
      'listingType': listingType,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (rentPeriod != null) 'rentPeriod': rentPeriod,
      if (swapFor != null) 'swapFor': swapFor,
      if (location != null) 'location': location,
      if (media.isNotEmpty) 'media': media,
    }, (data) => MouthUpPost.fromJson(data as Map<String, dynamic>));
  }

  Future<bool> toggleLike(String postId) async {
    final res = await _post('/posts/$postId/like', {}, (data) => data);
    return (res as Map<String, dynamic>)['liked'] as bool;
  }

  Future<MouthUpPost> updateListingStatus(String postId, String status) async {
    return _patch('/posts/$postId/listing-status', {'status': status},
        (data) => MouthUpPost.fromJson(data as Map<String, dynamic>));
  }

  Future<MouthUpPost> createPost(
    String content, {
    List<Map<String, String>> media = const [],
    String? mood,
  }) async {
    return _post('/posts', {
      'content': content,
      if (media.isNotEmpty) 'media': media,
      if (mood != null) 'mood': mood,
    }, (data) => MouthUpPost.fromJson(data as Map<String, dynamic>));
  }

  Future<SupportReactionType?> toggleSupportReaction(String postId, SupportReactionType type) async {
    return _post('/posts/$postId/support', {
      'type': supportReactionToApi(type),
    }, (data) {
      final map = data as Map<String, dynamic>;
      return supportReactionFromApi(map['reaction'] as String?);
    });
  }

  Future<Map<String, String>> uploadMedia(Uint8List bytes, String filename) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _dio.post(
        '/media/upload',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = res.data as Map<String, dynamic>;
      return {'type': data['type'] as String, 'url': data['url'] as String};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<MouthUpPost> updatePost(String id, String content) async {
    return _patch('/posts/$id', {'content': content}, (data) => MouthUpPost.fromJson(data as Map<String, dynamic>));
  }

  Future<void> deletePost(String id) => _delete('/posts/$id', (_) {});

  Future<bool> toggleSave(String id) async {
    final res = await _post('/posts/$id/save', {}, (data) => data);
    return (res as Map<String, dynamic>)['saved'] as bool;
  }

  Future<List<MouthUpPost>> fetchMyPosts() async {
    return _get('/posts/mine', (data) {
      final items = (data as Map<String, dynamic>)['items'] as List;
      return items.map((e) => MouthUpPost.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<MouthUpPost>> fetchSavedPosts() async {
    return _get('/posts/saved', (data) {
      final items = (data as Map<String, dynamic>)['items'] as List;
      return items.map((e) => MouthUpPost.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  // — Comments —

  Future<List<PostComment>> fetchComments(String postId) async {
    return _get('/posts/$postId/comments', (data) {
      return (data as List).map((e) => PostComment.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<PostComment> addComment(String postId, String content) async {
    return _post('/posts/$postId/comments', {'content': content},
        (data) => PostComment.fromJson(data as Map<String, dynamic>));
  }

  Future<void> deleteComment(String postId, String commentId) =>
      _delete('/posts/$postId/comments/$commentId', (_) {});

  Future<void> reportPost(String id, String reason) =>
      _post('/posts/$id/report', {'reason': reason}, (_) {});

  Future<void> reportComment(String id, String reason) =>
      _post('/comments/$id/report', {'reason': reason}, (_) {});

  Future<void> reportUser(String username, String reason) =>
      _post('/users/$username/report', {'reason': reason}, (_) {});

  // — Notifications —

  Future<List<AppNotification>> fetchNotifications() async {
    return _get('/notifications', (data) {
      return (data as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> markNotificationRead(String id) => _patch('/notifications/$id/read', {}, (_) {});

  Future<void> markAllNotificationsRead() => _patch('/notifications/read-all', {}, (_) {});

  // — Messages —

  Future<List<DmConversation>> fetchConversations() async {
    return _get('/messages/conversations', (data) {
      return (data as List).map((e) => DmConversation.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<DirectMessage>> fetchMessages(String peer, String myNickname) async {
    return _get('/messages/${Uri.encodeComponent(peer)}', (data) {
      return (data as List)
          .map((e) => DirectMessage.fromJson(e as Map<String, dynamic>, peer, myNickname))
          .toList();
    });
  }

  Future<void> sendMessage(String peer, String content, {String type = 'TEXT'}) {
    return _post('/messages/${Uri.encodeComponent(peer)}', {'content': content, 'type': type}, (_) {});
  }
}
