class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.route,
    this.type = NotificationType.general,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? route;
  final NotificationType type;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        route: route,
        type: type,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
        route: json['route'] as String?,
        type: notificationTypeFromApi(json['type'] as String?),
      );
}

enum NotificationType { listing, message, comment, follow, general }

NotificationType notificationTypeFromApi(String? value) {
  switch (value?.toUpperCase()) {
    case 'LISTING':
    case 'POST':
      return NotificationType.listing;
    case 'MESSAGE':
    case 'DM':
      return NotificationType.message;
    case 'COMMENT':
      return NotificationType.comment;
    case 'FOLLOW':
      return NotificationType.follow;
    case 'SYSTEM':
    case 'REPORT_UPDATE':
      return NotificationType.general;
    default:
      return NotificationType.general;
  }
}

class BlockedUser {
  const BlockedUser({required this.nickname});

  final String nickname;
}
