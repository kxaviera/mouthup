import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Registers the device for FCM push notifications.
class PushService {
  PushService({FlutterLocalNotificationsPlugin? localNotifications})
      : _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _localNotifications;
  bool _initialized = false;

  Future<void> init(Future<void> Function(String token) registerToken) async {
    if (kIsWeb || !DefaultFirebaseOptions.isConfigured || _initialized) return;

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'mouthup_default',
        'MouthUp',
        description: 'Notifications for messages and activity',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotifications.initialize(initSettings);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await registerToken(token);

    FirebaseMessaging.instance.onTokenRefresh.listen(registerToken);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null || kIsWeb) return;
      if (defaultTargetPlatform != TargetPlatform.android) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mouthup_default',
            'MouthUp',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    _initialized = true;
  }
}
