import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savorly/main.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/state/recipe_store.dart';
import 'package:savorly/state/theme_controller.dart';

Recipe _buildRecipe(String id, String title) => Recipe(
  id: id,
  title: title,
  description: 'A test recipe.',
  category: 'dinner',
  imageUrl: '',
  prepMinutes: 10,
  cookMinutes: 20,
  servings: 4,
  difficulty: 'Easy',
  calories: 400,
  rating: 4.5,
  ratingCount: 10,
  authorName: 'Test Author',
  ingredients: const [],
  steps: const [],
);

void main() {
  testWidgets(
    'bottom nav switches between Home, Discover, Favorites, and Profile',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = RecipeStore(
        initialRecipes: [
          _buildRecipe('1', 'Test Pasta'),
          _buildRecipe('2', 'Test Salad'),
        ],
        categories: const [],
      );
      final themeController = ThemeController();

      await tester.pumpWidget(
        SavorlyApp(store: store, themeController: themeController),
      );
      await tester.pumpAndSettle();

      // Starts on Home.
      expect(find.text('Home'), findsWidgets);

      // Discover.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Discover'));
      await tester.pumpAndSettle();
      expect(find.text('Discover'), findsWidgets);

      // Favorites.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Favorites'), findsWidgets);

      // Profile.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsWidgets);
    },
  );
}
