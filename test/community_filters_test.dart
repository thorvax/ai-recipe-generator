import 'package:flutter_test/flutter_test.dart';
import 'package:meal_mind/core/utils/community_filters.dart';
import 'package:meal_mind/models/posted_recipe.dart';
import 'package:meal_mind/models/recipe.dart';
import 'package:meal_mind/models/recipe_ingredient.dart';

PostedRecipe _post({
  String id = 'p1',
  String name = 'Garlic Pasta',
  String caption = '',
  String poster = 'Jamie Reyes',
  String cuisine = 'Italian',
  String mealType = 'Dinner',
  String diet = 'None',
  List<String> ingredients = const ['Spaghetti', 'Garlic'],
}) {
  final recipe = Recipe.blank(userId: 'u1').copyWith(
    name: name,
    cuisine: cuisine,
    mealType: mealType,
    dietaryRestriction: diet,
    ingredients: [
      for (final i in ingredients)
        RecipeIngredient(name: i, quantity: '1', unit: ''),
    ],
  );
  return PostedRecipe(
    id: id,
    userId: 'u1',
    posterName: poster,
    recipeId: 'r1',
    caption: caption,
    recipe: recipe,
  );
}

void main() {
  group('dietTagsOf', () {
    test('splits, trims, lower-cases and ignores "None"', () {
      expect(dietTagsOf(' Vegan ,Gluten-free'), {'vegan', 'gluten-free'});
      expect(dietTagsOf('None'), isEmpty);
      expect(dietTagsOf(''), isEmpty);
    });
  });

  group('matchesSearch', () {
    final post = _post(
      caption: 'Quick weeknight dinner',
      diet: 'Vegetarian',
      ingredients: ['Spaghetti', 'Parmesan cheese'],
    );

    test('empty or blank query matches everything', () {
      expect(matchesSearch(post, ''), isTrue);
      expect(matchesSearch(post, '   '), isTrue);
    });

    test('matches each searchable field, case-insensitive substring', () {
      expect(matchesSearch(post, 'garlic'), isTrue, reason: 'name');
      expect(matchesSearch(post, 'WEEKNIGHT'), isTrue, reason: 'caption');
      expect(matchesSearch(post, 'reyes'), isTrue, reason: 'poster');
      expect(matchesSearch(post, 'ital'), isTrue, reason: 'cuisine');
      expect(matchesSearch(post, 'dinner'), isTrue, reason: 'meal type');
      expect(matchesSearch(post, 'vegetar'), isTrue, reason: 'diet tag');
      expect(matchesSearch(post, 'parmesan'), isTrue, reason: 'ingredient');
    });

    test('does not match unrelated text', () {
      expect(matchesSearch(post, 'chocolate'), isFalse);
    });

    test('"Any" cuisine / meal type and "None" diet are not searchable', () {
      final plain = _post(cuisine: 'Any', mealType: 'Any', diet: 'None');
      expect(matchesSearch(plain, 'any'), isFalse);
      expect(matchesSearch(plain, 'none'), isFalse);
    });
  });

  group('matchesDiet', () {
    final veganGf = _post(diet: 'Vegan, Gluten-free');

    test('no filters matches everything, including "None"', () {
      expect(matchesDiet(_post(diet: 'None'), const []), isTrue);
    });

    test('requires ALL active filters, case-insensitive', () {
      expect(matchesDiet(veganGf, ['vegan']), isTrue);
      expect(matchesDiet(veganGf, ['VEGAN', 'gluten-free']), isTrue);
      expect(matchesDiet(veganGf, ['Vegan', 'Dairy-free']), isFalse);
    });

    test('"None" recipes never match an active filter', () {
      expect(matchesDiet(_post(diet: 'None'), ['Vegan']), isFalse);
    });

    test('compares whole tags, not substrings', () {
      expect(matchesDiet(_post(diet: 'Low-carb'), ['carb']), isFalse);
    });

    test('custom needs work like presets', () {
      expect(matchesDiet(_post(diet: 'Vegan, Nut-free'), ['nut-free']), isTrue);
    });
  });

  group('filterPosts', () {
    final posts = [
      _post(id: 'a', name: 'Vegan Curry', diet: 'Vegan'),
      _post(id: 'b', name: 'Vegan Brownies', diet: 'Vegan, Gluten-free'),
      _post(id: 'c', name: 'Beef Stew', diet: 'None'),
    ];
    List<String> ids(List<PostedRecipe> l) => l.map((p) => p.id).toList();

    test('no search and no filters returns all, in order', () {
      expect(ids(filterPosts(posts)), ['a', 'b', 'c']);
    });

    test('diet filters only', () {
      expect(ids(filterPosts(posts, diet: ['vegan'])), ['a', 'b']);
      expect(ids(filterPosts(posts, diet: ['vegan', 'gluten-free'])), ['b']);
    });

    test('search AND diet filters', () {
      expect(ids(filterPosts(posts, query: 'curry', diet: ['vegan'])), ['a']);
      expect(ids(filterPosts(posts, query: 'stew', diet: ['vegan'])), isEmpty);
    });
  });
}
