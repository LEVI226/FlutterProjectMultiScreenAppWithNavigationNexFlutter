import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/category.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/screens/discover_screen.dart';
import 'package:savorly/state/recipe_store.dart';

Recipe _recipe({
  required String id,
  required String title,
  required String category,
  required int prepMinutes,
  required int cookMinutes,
  required double rating,
}) => Recipe(
  id: id,
  title: title,
  description: 'desc',
  category: category,
  imageUrl: '',
  prepMinutes: prepMinutes,
  cookMinutes: cookMinutes,
  servings: 2,
  difficulty: 'Easy',
  calories: 300,
  rating: rating,
  ratingCount: 5,
  authorName: 'Chef Test',
  ingredients: const [],
  steps: const [],
);

Widget _wrap(RecipeStore store) => MaterialApp(
  home: RecipeStoreScope(store: store, child: const DiscoverScreen()),
);

void main() {
  late RecipeStore store;

  setUp(() {
    store = RecipeStore(
      initialRecipes: [
        _recipe(id: '1', title: 'Pasta Bolognese', category: 'dinner', prepMinutes: 15, cookMinutes: 30, rating: 4.8),
        _recipe(id: '2', title: 'Quick Salad', category: 'lunch', prepMinutes: 10, cookMinutes: 0, rating: 4.2),
        _recipe(id: '3', title: 'Pancakes', category: 'breakfast', prepMinutes: 10, cookMinutes: 15, rating: 4.5),
      ],
      categories: const [
        Category(id: 'dinner', name: 'Dinner', emoji: '🍝'),
        Category(id: 'lunch', name: 'Lunch', emoji: '🥗'),
        Category(id: 'breakfast', name: 'Breakfast', emoji: '🥞'),
      ],
    );
  });

  testWidgets('shows all recipes by default', (tester) async {
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    expect(find.text('Pasta Bolognese'), findsOneWidget);
    expect(find.text('Quick Salad'), findsOneWidget);
    expect(find.text('Pancakes'), findsOneWidget);
  });

  testWidgets('typing in the search field filters the recipe list', (tester) async {
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Pasta');
    await tester.pumpAndSettle();

    expect(find.text('Pasta Bolognese'), findsOneWidget);
    expect(find.text('Quick Salad'), findsNothing);
    expect(find.text('Pancakes'), findsNothing);
  });

  testWidgets('tapping a category chip filters to that category', (tester) async {
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();

    expect(find.text('Quick Salad'), findsOneWidget);
    expect(find.text('Pasta Bolognese'), findsNothing);
    expect(find.text('Pancakes'), findsNothing);
  });

  testWidgets('tapping the grid-density toggle changes its icon', (tester) async {
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.view_module_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Grid density'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.grid_view), findsOneWidget);
    expect(find.byIcon(Icons.view_module_outlined), findsNothing);
  });
}
