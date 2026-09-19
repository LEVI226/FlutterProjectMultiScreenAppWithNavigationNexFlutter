import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/category.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/state/recipe_store.dart';

Recipe _recipe(
  String id, {
  String category = 'Dinner',
  int prepMinutes = 20,
  double rating = 4.0,
}) {
  return Recipe(
    id: id,
    title: 'Recipe $id',
    description: 'desc',
    category: category,
    imageUrl: 'https://images.unsplash.com/photo-test',
    prepMinutes: prepMinutes,
    cookMinutes: 10,
    servings: 2,
    difficulty: 'Easy',
    calories: 300,
    rating: rating,
    ratingCount: 10,
    authorName: 'Chef Test',
    ingredients: const [],
    steps: const [],
  );
}

void main() {
  late RecipeStore store;

  setUp(() {
    store = RecipeStore(
      initialRecipes: [
        _recipe('a', category: 'Dinner', prepMinutes: 45, rating: 4.9),
        _recipe('b', category: 'Breakfast', prepMinutes: 10, rating: 4.2),
        _recipe('c', category: 'Dinner', prepMinutes: 20, rating: 4.5),
      ],
      categories: const [Category(id: 'Dinner', name: 'Dinner', emoji: '🍲')],
    );
  });

  test('featured returns the highest-rated recipe', () {
    expect(store.featured?.id, 'a');
  });

  test('quickAndEasy only includes recipes with prepMinutes <= 30', () {
    expect(store.quickAndEasy.map((r) => r.id), containsAll(['b', 'c']));
    expect(store.quickAndEasy.map((r) => r.id), isNot(contains('a')));
  });

  test('byCategory filters by category id', () {
    expect(
      store.byCategory('Dinner').map((r) => r.id),
      containsAll(['a', 'c']),
    );
    expect(store.byCategory('Dinner'), hasLength(2));
  });

  test('search matches by title (case-insensitive)', () {
    expect(store.search('RECIPE A').map((r) => r.id), ['a']);
    expect(store.search(''), hasLength(3));
  });

  test('toggleFavorite adds then removes and notifies listeners', () {
    var notifications = 0;
    store.addListener(() => notifications++);

    store.toggleFavorite('a');
    expect(store.isFavorite('a'), isTrue);
    expect(store.favorites.map((r) => r.id), ['a']);

    store.toggleFavorite('a');
    expect(store.isFavorite('a'), isFalse);
    expect(store.favorites, isEmpty);

    expect(notifications, 2);
  });

  test('addRecipe inserts the new recipe and notifies listeners', () {
    var notified = false;
    store.addListener(() => notified = true);

    store.addRecipe(_recipe('new'));

    expect(store.all.map((r) => r.id), contains('new'));
    expect(notified, isTrue);
  });
}
