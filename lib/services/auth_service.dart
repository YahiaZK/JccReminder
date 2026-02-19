import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ADD THIS

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;
  Future<void> _upsertUserDocument(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> subscribeToNotifications() async {
    final user = currentUser;
    if (user == null) return;

    await _upsertUserDocument(user);
    await _fcm.requestPermission();

    final token = await _fcm.getToken();
    if (token == null) {
      debugPrint("Could not get FCM token for subscription.");
      return;
    }

    final tokensRef = _firestore.collection('users').doc(user.uid);
    await tokensRef.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
    debugPrint("Subscribed to notifications. Token saved for user ${user.uid}");
  }

  Future<void> unsubscribeFromNotifications() async {
    final user = currentUser;
    if (user == null) return;

    final token = await _fcm.getToken();
    if (token == null) {
      debugPrint(
        "Could not get FCM token for unsubscription. Nothing to remove.",
      );
      return;
    }

    final tokensRef = _firestore.collection('users').doc(user.uid);
    await tokensRef.update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });

    await _fcm.deleteToken();

    debugPrint(
      "Unsubscribed from notifications. Token removed for user ${user.uid}",
    );
  }

  Future<void> handlePostSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    final bool areNotificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;

    if (areNotificationsEnabled) {
      await subscribeToNotifications();
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await handlePostSignIn();
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign in failed: ${e.message}");
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await handlePostSignIn();
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Sign up failed: ${e.message}");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint("Google sign in was cancelled by the user.");
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      if (userCredential.user != null) {
        await handlePostSignIn();
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Google sign in failed with FirebaseAuthException: ${e.message}",
      );
      rethrow;
    } catch (e) {
      debugPrint("An unexpected error occurred during Google sign in: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
    debugPrint("User signed out from Firebase and Google.");
  }
}
