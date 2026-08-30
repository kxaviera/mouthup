import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase/firebase_options.dart';

/// Firebase Authentication — Google sign-in and email/password via Firebase.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            (kIsWeb
                ? null
                : GoogleSignIn(
                    serverClientId:
                        '55773552314-cpq6qmi8oddb9ovuohanc6kl3cv1s7ap.apps.googleusercontent.com',
                  ));

  final FirebaseAuth _auth;
  final GoogleSignIn? _googleSignIn;

  static bool get isAvailable => DefaultFirebaseOptions.isConfigured;

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    final googleUser = await _googleSignIn!.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (!kIsWeb && _googleSignIn != null) _googleSignIn!.signOut(),
    ]);
  }
}
