import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:savorly/main.dart';
import 'package:savorly/models/category.dart';
import 'package:savorly/state/locale_controller.dart';
import 'package:savorly/state/recipe_store.dart';
import 'package:savorly/state/theme_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('publishing a new recipe makes it appear on Discover', (
    tester,
  ) async {
    // AppShell switches from the phone NavigationBar (NavigationDestination)
    // to a tablet NavigationRail (NavigationRailDestination) at width >=
    // 600. The real browser window driving this test on a web device is
    // wider than that, so pin a phone-sized view to keep the bottom nav
    // bar in play — matching the pattern test/app_navigation_test.dart and
    // integration_test/favorite_flow_test.dart already use for the same
    // reason.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = RecipeStore(
      initialRecipes: const [],
      // AddRecipeScreen's category dropdown defaults its selected value to
      // the literal 'Dinner' (lib/screens/add_recipe_screen.dart), and
      // DropdownButtonFormField asserts that its value matches exactly one
      // item's value. The category id must match that casing exactly (see
      // test/screens/add_recipe_screen_test.dart, which uses the same
      // 'Dinner' id for the same reason) or the dropdown throws when the
      // form builds.
      categories: const [Category(id: 'Dinner', name: 'Dinner', emoji: '🍝')],
    );

    await tester.pumpWidget(
      SavorlyApp(
        store: store,
        themeController: ThemeController(),
        localeController: LocaleController(deviceLocale: const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Discover, then to Add Recipe via its FAB.
    await tester.tap(find.widgetWithText(NavigationDestination, 'Discover'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Recipe'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Recipe Name *'),
      'Integration Test Tacos',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description *'),
      'A description long enough for validation.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ingredient'),
      'Tortilla',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Describe this cooking step'),
      'Fill and fold.',
    );

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Publish Recipe'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Publish Recipe'));
    await tester.pumpAndSettle();

    // Publishing pops back to Discover. With only this one recipe in the
    // store (and the store starting empty), Discover's grid renders it
    // exactly once — unlike Home, Discover has no separate
    // featured/popular/quick-and-easy sections that could render the same
    // title more than once, so asserting uniqueness here is safe.
    expect(find.text('Integration Test Tacos'), findsOneWidget);
    expect(store.all, hasLength(1));
  });
}
