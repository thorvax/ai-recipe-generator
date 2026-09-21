import 'package:cloud_firestore/cloud_firestore.dart';

/// CATEGORY entity. Stored in Firestore at categories/{id}.
class Category {
  final String id;
  final String userId;
  final String name;
  final DateTime? createdAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.createdAt,
  });

  /// Categories offered in the "Choose a category" pop-up.
  /// They are only created in Firestore when the user actually uses them.
  static const List<String> presets = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
    'Vegetarian',
    'Quick meals',
  ];

  Map<String, dynamic> toMap() => {
        'category_id': id,
        'user_id': userId,
        'category_name': name,
        'created_at': FieldValue.serverTimestamp(),
      };

  factory Category.fromMap(Map<String, dynamic> map, {required String id}) {
    final ts = map['created_at'];
    return Category(
      id: id,
      userId: map['user_id']?.toString() ?? '',
      name: map['category_name']?.toString() ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
