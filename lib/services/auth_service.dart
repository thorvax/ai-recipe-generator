import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/env.dart';
import '../models/app_user.dart';

/// A friendly error that the UI can show directly.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Talks to Firebase Auth + the Firestore "users" collection.
/// No UI code in here.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());

      final appUser = AppUser(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
      );
      await _db.collection('users').doc(user.uid).set(appUser.toMap());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  /// Reads the user's saved default dietary needs (users/{uid}.dietary_needs).
  Future<List<String>> getDietaryPreferences() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    try {
      final doc = await _db
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final raw = doc.data()?['dietary_needs'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Saves the user's default dietary needs, used to pre-fill new requests.
  Future<void> updateDietaryPreferences(List<String> needs) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('You are not logged in.');
    try {
      await _db.collection('users').doc(user.uid).set({
        'user_id': user.uid,
        'email': user.email,
        'dietary_needs': needs,
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
    } catch (_) {
      throw AuthException('Could not save your preferences. Try again.');
    }
  }

  /// Changes the display name in Firebase Auth and in users/{uid}.
  Future<void> updateName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('You are not logged in.');
    final trimmed = name.trim();
    try {
      await user.updateDisplayName(trimmed);
      await user.reload();
      await _db.collection('users').doc(user.uid).set({
        'user_id': user.uid,
        'email': user.email,
        'name': trimmed,
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  // ---------- Google sign-in ----------

  bool _googleInitialized = false;

  /// google_sign_in v7 must be initialized exactly once before use.
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: Env.googleServerClientId,
    );
    _googleInitialized = true;
  }

  /// Returns true when signed in, false if the user closed the Google
  /// account picker (not an error). Throws [AuthException] on real failures.
  Future<bool> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw AuthException('Google sign-in failed. Please try again.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user != null) await _ensureUserDocument(user);
      return true;
    } on GoogleSignInException catch (e) {
      debugPrint('Google sign-in error: ${e.code} ${e.description}');
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          return false;
        case GoogleSignInExceptionCode.interrupted:
          throw AuthException('Sign-in was interrupted. Please try again.');
        case GoogleSignInExceptionCode.uiUnavailable:
          throw AuthException('Google sign-in is not available on this device.');
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw AuthException('Google sign-in is not set up correctly.');
        default:
          throw AuthException('Google sign-in failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  /// First-time Google users have no users/{uid} document yet (sign up
  /// creates it for email accounts). Best-effort: a failure here must not
  /// block the login itself.
  Future<void> _ensureUserDocument(User user) async {
    try {
      final ref = _db.collection('users').doc(user.uid);
      final snap = await ref.get().timeout(const Duration(seconds: 8));
      if (snap.exists) return;

      final email = user.email ?? '';
      final name = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : (email.contains('@') ? email.split('@').first : 'Cook');

      final appUser = AppUser(uid: user.uid, name: name, email: email);
      await ref.set(appUser.toMap()).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('ensureUserDocument failed: $e');
    }
  }

  Future<void> signOut() async {
    // Also sign out of Google so the account picker shows next time.
    final usedGoogle = _auth.currentUser?.providerData
            .any((p) => p.providerId == 'google.com') ??
        false;
    if (usedGoogle) {
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google signOut failed: $e');
      }
    }
    await _auth.signOut();
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
