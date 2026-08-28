// Generated from google-services.json (project: mouthup)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured => true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError('Firebase is not supported on this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBVPRb1iezFBhIPedk1mgPleKJGjQ0QXmk',
    appId: '1:55773552314:android:6bd3815f8a267845922c83',
    messagingSenderId: '55773552314',
    projectId: 'mouthup',
    authDomain: 'mouthup.firebaseapp.com',
    storageBucket: 'mouthup.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBVPRb1iezFBhIPedk1mgPleKJGjQ0QXmk',
    appId: '1:55773552314:android:6bd3815f8a267845922c83',
    messagingSenderId: '55773552314',
    projectId: 'mouthup',
    storageBucket: 'mouthup.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzwB8a7ZJfVggRb8gdpOOrS5AuGZVmNlA',
    appId: '1:55773552314:ios:614cd75c63be8dd6922c83',
    messagingSenderId: '55773552314',
    projectId: 'mouthup',
    storageBucket: 'mouthup.firebasestorage.app',
    iosBundleId: 'com.mouthup.mouthup',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBzwB8a7ZJfVggRb8gdpOOrS5AuGZVmNlA',
    appId: '1:55773552314:ios:614cd75c63be8dd6922c83',
    messagingSenderId: '55773552314',
    projectId: 'mouthup',
    storageBucket: 'mouthup.firebasestorage.app',
    iosBundleId: 'com.mouthup.mouthup',
  );
}
