class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.route,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? route;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        route: route,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
        route: json['route'] as String?,
      );
}

List<AppNotification> mockNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'n1',
      title: 'NightWalker',
      body: 'replied to a thread you commented on',
      createdAt: now.subtract(const Duration(minutes: 12)),
      route: '/post/1',
    ),
    AppNotification(
      id: 'n2',
      title: 'SilentOwl',
      body: 'replied to your post',
      createdAt: now.subtract(const Duration(hours: 1)),
      route: '/post/4',
    ),
    AppNotification(
      id: 'n3',
      title: 'New message',
      body: 'from SilentOwl',
      createdAt: now.subtract(const Duration(hours: 2)),
      route: '/chats',
    ),
    AppNotification(
      id: 'n4',
      title: 'Daily check-in',
      body: 'Share what\'s on your mind today',
      createdAt: now.subtract(const Duration(hours: 5)),
      read: true,
    ),
  ];
}

class BlockedUser {
  const BlockedUser({required this.nickname});

  final String nickname;
}
