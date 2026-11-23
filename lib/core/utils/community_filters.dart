import '../../models/posted_recipe.dart';

/// Pure helpers for the Community feed's search box and dietary chips.
/// No Flutter or Firebase here, so they are easy to unit test.

String _norm(String s) => s.trim().toLowerCase();

/// "Vegetarian, Gluten-free" -> {"vegetarian", "gluten-free"}.
/// "None" and empty parts are ignored.
Set<String> dietTagsOf(String dietaryRestriction) {
  return dietaryRestriction
      .split(',')
      .map(_norm)
      .where((s) => s.isNotEmpty && s != 'none')
      .toSet();
}

/// Case-insensitive substring match against the recipe name, caption,
/// poster name, cuisine, meal type, dietary tags and ingredient names.
/// An empty query matches everything.
bool matchesSearch(PostedRecipe post, String query) {
  final q = _norm(query);
  if (q.isEmpty) return true;

  final r = post.recipe;
  final fields = <String>[
    r.name,
    post.caption,
    post.posterName,
    if (r.cuisine != 'Any') r.cuisine,
    if (r.mealType != 'Any') r.mealType,
    ...dietTagsOf(r.dietaryRestriction),
    for (final i in r.ingredients) i.name,
  ];
  return fields.any((f) => f.toLowerCase().contains(q));
}

/// True when the recipe has ALL of [filters] as dietary tags
/// (whole tags, case-insensitive). No filters matches everything.
bool matchesDiet(PostedRecipe post, Iterable<String> filters) {
  final wanted = filters.map(_norm).where((f) => f.isNotEmpty).toSet();
  if (wanted.isEmpty) return true;
  return dietTagsOf(post.recipe.dietaryRestriction).containsAll(wanted);
}

/// Search AND dietary filters, keeping the original order.
List<PostedRecipe> filterPosts(
  List<PostedRecipe> posts, {
  String query = '',
  Iterable<String> diet = const [],
}) {
  final dietList = diet.toList();
  return posts
      .where((p) => matchesDiet(p, dietList) && matchesSearch(p, query))
      .toList();
}
