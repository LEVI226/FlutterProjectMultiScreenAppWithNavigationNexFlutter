import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:savorly/main.dart';
import 'package:savorly/models/category.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/state/locale_controller.dart';
import 'package:savorly/state/recipe_store.dart';
import 'package:savorly/state/theme_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('favoriting a recipe from Home makes it appear on Favorites', (
    tester,
  ) async {
    // AppShell switches from the phone NavigationBar (NavigationDestination)
    // to a tablet NavigationRail (NavigationRailDestination) at width >=
    // 600. The real browser window driving this test on a web device is
    // wider than that, so pin a phone-sized view to keep the bottom nav
    // bar in play — matching the pattern test/app_navigation_test.dart
    // already uses for the same reason.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = RecipeStore(
      initialRecipes: [
        const Recipe(
          id: 'r1',
          title: 'Integration Test Pasta',
          description: 'desc',
          category: 'dinner',
          imageUrl: '',
          prepMinutes: 15,
          cookMinutes: 20,
          servings: 2,
          difficulty: 'Easy',
          calories: 400,
          rating: 4.9,
          ratingCount: 10,
          authorName: 'Chef Test',
          ingredients: [],
          steps: [],
        ),
      ],
      categories: const [Category(id: 'dinner', name: 'Dinner', emoji: '🍝')],
    );

    await tester.pumpWidget(
      SavorlyApp(
        store: store,
        themeController: ThemeController(),
        localeController: LocaleController(deviceLocale: const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    // Home shows the recipe as the Featured card (it's the only recipe, so
    // it's also the highest-rated). With a single recipe in the store it
    // also surfaces in the Popular carousel (top-rated) and the Quick &
    // Easy section (prepMinutes <= 30), so more than one widget renders its
    // title on Home — assert presence, not uniqueness, here.
    expect(find.text('Integration Test Pasta'), findsWidgets);

    // Open the recipe detail screen.
    await tester.tap(find.text('Integration Test Pasta').first);
    await tester.pumpAndSettle();

    // Tap the favorite icon in the app bar.
    await tester.tap(find.byTooltip('Favorite'));
    await tester.pumpAndSettle();
    expect(store.isFavorite('r1'), isTrue);

    // Navigate to Favorites via the bottom nav.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Integration Test Pasta'), findsOneWidget);
    expect(find.text('No favorites yet'), findsNothing);
  });
}
