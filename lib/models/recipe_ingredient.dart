/// RECIPE_INGREDIENT entity (stored inside the recipe document).
class RecipeIngredient {
  final String name;
  final String quantity; // text, so "1/2" or "2" both work
  final String unit; // e.g. "cups", "g", or "" for "2 eggs"

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      name: map['ingredient_name']?.toString() ?? '',
      quantity: map['quantity']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'ingredient_name': name,
        'quantity': quantity,
        'unit': unit,
      };

  /// "2 cups rice", "3 garlic cloves"
  String get display =>
      [quantity, unit, name].where((s) => s.trim().isNotEmpty).join(' ');
}
