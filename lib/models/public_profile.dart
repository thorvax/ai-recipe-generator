import 'package:cloud_firestore/cloud_firestore.dart';

/// Public part of a user, readable by every signed-in user.
/// Stored at public_profiles/{uid}. (users/{uid} stays private.)
///
/// Avatar shown, in order: [avatarBase64] (custom upload) →
/// [photoUrl] (Google profile photo) → default icon/initial.
class PublicProfile {
  final String uid; // user_id
  final String name;
  final String? avatarBase64; // avatar_b64, custom picture
  final String? photoUrl; // photo_url, Google photo
  final DateTime? updatedAt;

  const PublicProfile({
    required this.uid,
    required this.name,
    this.avatarBase64,
    this.photoUrl,
    this.updatedAt,
  });

  bool get hasCustomAvatar => avatarBase64 != null && avatarBase64!.isNotEmpty;

  factory PublicProfile.fromMap(
    Map<String, dynamic> map, {
    required String uid,
  }) {
    final ts = map['updated_at'];
    String? str(Object? v) {
      final s = v?.toString() ?? '';
      return s.isEmpty ? null : s;
    }

    return PublicProfile(
      uid: uid,
      name: map['name']?.toString() ?? 'Cook',
      avatarBase64: str(map['avatar_b64']),
      photoUrl: str(map['photo_url']),
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  /// Google photo URLs end in "=s96-c" (96 px). Ask for 256 px instead.
  static String? normalizeGooglePhotoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final pattern = RegExp(r'=s\d+-c$');
    return pattern.hasMatch(url) ? url.replaceFirst(pattern, '=s256-c') : url;
  }
}
