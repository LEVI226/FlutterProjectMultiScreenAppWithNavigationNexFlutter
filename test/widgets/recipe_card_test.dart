import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/widgets/recipe_card.dart';

Recipe _testRecipe() => const Recipe(
  id: 'r1',
  title: 'Test Pasta',
  description: 'desc',
  category: 'Dinner',
  imageUrl: 'https://images.unsplash.com/photo-test',
  prepMinutes: 20,
  cookMinutes: 10,
  servings: 2,
  difficulty: 'Easy',
  calories: 400,
  rating: 4.5,
  ratingCount: 10,
  authorName: 'Chef Test',
  ingredients: [],
  steps: [],
);

void main() {
  testWidgets(
    'shows title, category badge, and an outlined heart when not favorited',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeCard(
              recipe: _testRecipe(),
              isFavorite: false,
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Pasta'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    },
  );

  testWidgets(
    'shows a filled heart when favorited and calls onFavoriteToggle on tap',
    (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeCard(
              recipe: _testRecipe(),
              isFavorite: true,
              onTap: () {},
              onFavoriteToggle: () => toggled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite));
      expect(toggled, isTrue);
    },
  );

  testWidgets('calls onTap when the card is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecipeCard(
            recipe: _testRecipe(),
            isFavorite: false,
            onTap: () => tapped = true,
            onFavoriteToggle: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Test Pasta'));
    expect(tapped, isTrue);
  });
}
