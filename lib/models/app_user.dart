import 'package:cloud_firestore/cloud_firestore.dart';

/// USER entity from the ERD. Stored in Firestore at users/{uid}.
class AppUser {
  final String uid; // user_id
  final String name;
  final String email;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
  });

  /// Used when writing a NEW user (createdAt is filled in by the server).
  Map<String, dynamic> toMap() => {
        'user_id': uid,
        'name': name,
        'email': email,
        'created_at': FieldValue.serverTimestamp(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final ts = map['created_at'];
    return AppUser(
      uid: map['user_id'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
