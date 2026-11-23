import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/env.dart';
import '../models/app_user.dart';
import 'profile_service.dart';
import 'username_service.dart';

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
  final ProfileService _profiles = ProfileService();
  final UsernameService _usernames = UsernameService();

  User? get currentUser => _auth.currentUser;

  /// When a verification email was last sent in this app session, or null
  /// (older accounts that log in were never sent one).
  static DateTime? lastVerificationSentAt;

  /// Sends the "Verify your email" link (again).
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('You are not logged in.');
    try {
      await user.sendEmailVerification();
      lastVerificationSentAt = DateTime.now();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  /// Asks Firebase again whether the email is verified (after the user
  /// tapped the link in their mail app). Also refreshes the login token,
  /// so the Firestore rules and the recipe server see "verified" right away.
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final fresh = _auth.currentUser;
      final verified = fresh?.emailVerified ?? false;
      if (verified) await fresh!.getIdToken(true);
      return verified;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final chosen = UsernameService.normalize(username);
    try {
      // Check first, so a taken name doesn't create an account at all.
      if (!await _usernames.isAvailable(chosen)) {
        throw UsernameTakenException();
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(chosen);
      // "Verify your email" link (best effort: they can resend it from the
      // Verify Email screen).
      try {
        await user.sendEmailVerification();
        lastVerificationSentAt = DateTime.now();
      } catch (e) {
        debugPrint('send verification email failed: $e');
      }

      final appUser = AppUser(uid: user.uid, name: chosen, email: email.trim());
      await _db.collection('users').doc(user.uid).set(appUser.toMap());

      var finalName = chosen;
      try {
        finalName = await _usernames.claim(
          uid: user.uid,
          email: user.email ?? '',
          text: chosen,
        );
      } catch (e) {
        // Taken in the last second by someone else: give a close one.
        debugPrint('claim username failed: $e');
        finalName = await _usernames.ensure(
          uid: user.uid,
          email: user.email ?? '',
          nameOrEmail: chosen,
        );
        await user.updateDisplayName(finalName);
      }

      // Public name/avatar other users can see (best-effort).
      await _profiles.ensureSafely(uid: user.uid, name: finalName);
    } on UsernameTakenException catch (e) {
      throw AuthException(e.message);
    } on TimeoutException {
      throw AuthException(_timeoutMessage);
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

  /// Changes the username (if it's free) everywhere it's stored: the
  /// usernames collection, users/{uid}, the Auth display name and
  /// public_profiles/{uid}.name. Returns the saved username.
  Future<String> changeUsername(String text) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('You are not logged in.');

    final String username;
    try {
      username = await _usernames.claim(
        uid: user.uid,
        email: user.email ?? '',
        text: text,
      );
      await user.updateDisplayName(username);
      await user.reload();
    } on UsernameTakenException catch (e) {
      throw AuthException(e.message);
    } on TimeoutException {
      throw AuthException(_timeoutMessage);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    } on FirebaseException {
      throw AuthException('Could not save your username. Please try again.');
    }

    // Other users see this name on posts and comments (best-effort).
    try {
      await _profiles.updateName(uid: user.uid, name: username);
    } catch (e) {
      debugPrint('public profile name sync failed: $e');
    }
    return username;
  }

  /// Runs after every login and when the app opens already signed in
  /// (same as the website's syncAccount). Makes sure the account is
  /// complete, so phone sign-up, email login, Google login and the
  /// website all end up the same:
  ///   1. users/{uid} exists
  ///   2. it has a username (older accounts and first Google logins get one
  ///      made from their name or email)
  ///   3. the Auth display name is that username
  ///   4. public_profiles/{uid} exists with that name (and the Google photo)
  /// Never throws: a problem here must not block using the app.
  Future<void> syncAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _ensureUserDocument(user);
      final username = await _usernames.ensure(
        uid: user.uid,
        email: user.email ?? '',
        nameOrEmail: _nameFor(user),
      );
      if (user.displayName != username) {
        await user.updateDisplayName(username);
        await user.reload();
      }
      // Creates the profile if missing; refreshes the Google photo only
      // when there's no custom avatar.
      final profile = await _profiles.ensure(
        uid: user.uid,
        name: username,
        googlePhotoUrl: ProfileService.googlePhotoUrlOf(user),
      );
      if (profile.name != username) {
        await _profiles.updateName(uid: user.uid, name: username);
      }
    } catch (e) {
      debugPrint('syncAccount failed: $e');
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
      // The users document, username and public profile are set up by
      // syncAccount(), which runs after every login (AuthProvider.afterLogin).
      await _auth.signInWithCredential(credential);
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
      final appUser =
          AppUser(uid: user.uid, name: _nameFor(user), email: email);
      await ref.set(appUser.toMap()).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('ensureUserDocument failed: $e');
    }
  }

  /// Display name, else the part of the email before "@", else "Cook".
  static String _nameFor(User user) {
    final name = user.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = user.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Cook';
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

  static const String _timeoutMessage =
      'Could not reach the server. Check your connection and try again.';

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
