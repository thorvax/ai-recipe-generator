import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/public_profile.dart';

/// Firestore access for public_profiles/{uid} (name + avatar that other
/// signed-in users can see). No UI code here.
class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Duration timeout = Duration(seconds: 8);
  static const int maxNameLength = 80; // matches the Firestore rule

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('public_profiles').doc(uid);

  /// The Google profile photo of a Firebase user (null for email accounts).
  static String? googlePhotoUrlOf(User? user) {
    if (user == null) return null;
    for (final p in user.providerData) {
      if (p.providerId == 'google.com') {
        return PublicProfile.normalizeGooglePhotoUrl(
          p.photoURL ?? user.photoURL,
        );
      }
    }
    return null;
  }

  static String _cleanName(String name) {
    final n = name.trim().isEmpty ? 'Cook' : name.trim();
    return n.length > maxNameLength ? n.substring(0, maxNameLength) : n;
  }

  /// Null when the user has no public profile yet.
  Future<PublicProfile?> get(String uid) async {
    final snap = await _doc(uid).get().timeout(timeout);
    final data = snap.data();
    return data == null ? null : PublicProfile.fromMap(data, uid: uid);
  }

  /// Creates the profile if it is missing (sign-up, first Google login,
  /// or older accounts). For an existing profile it only refreshes the
  /// Google photo, and only when there is no custom avatar — a custom
  /// avatar is never overwritten.
  Future<PublicProfile> ensure({
    required String uid,
    required String name,
    String? googlePhotoUrl,
  }) async {
    final existing = await get(uid);

    if (existing == null) {
      final data = {
        'user_id': uid,
        'name': _cleanName(name),
        'avatar_b64': null,
        'photo_url': googlePhotoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      };
      await _doc(uid).set(data).timeout(timeout);
      return PublicProfile(
        uid: uid,
        name: _cleanName(name),
        photoUrl: googlePhotoUrl,
      );
    }

    final refreshPhoto =
        googlePhotoUrl != null &&
        !existing.hasCustomAvatar &&
        existing.photoUrl != googlePhotoUrl;
    if (!refreshPhoto) return existing;

    await _doc(uid)
        .set({
          'user_id': uid,
          'name': existing.name,
          'photo_url': googlePhotoUrl,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(timeout);
    return PublicProfile(
      uid: uid,
      name: existing.name,
      photoUrl: googlePhotoUrl,
    );
  }

  /// Same as [ensure] but never throws (used during sign-up / login so a
  /// profile problem cannot block signing in).
  Future<void> ensureSafely({
    required String uid,
    required String name,
    String? googlePhotoUrl,
  }) async {
    try {
      await ensure(uid: uid, name: name, googlePhotoUrl: googlePhotoUrl);
    } catch (e) {
      debugPrint('ensure public profile failed: $e');
    }
  }

  /// Saves a custom avatar (base64 JPEG). Pass null to remove it; the
  /// Google photo (if any) then shows again.
  Future<void> setAvatar({
    required String uid,
    required String name,
    required String? avatarBase64,
  }) {
    return _doc(uid)
        .set({
          'user_id': uid,
          'name': _cleanName(name),
          'avatar_b64': avatarBase64,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(timeout);
  }

  Future<void> updateName({required String uid, required String name}) {
    return _doc(uid)
        .set({
          'user_id': uid,
          'name': _cleanName(name),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(timeout);
  }
}
