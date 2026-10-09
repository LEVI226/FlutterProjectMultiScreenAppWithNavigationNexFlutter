import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savorly/main.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/state/recipe_store.dart';
import 'package:savorly/state/theme_controller.dart';

// HomeScreen renders recipe images (via RecipeCard, FeaturedRecipeCard, and
// QuickRecipeTile) through CachedNetworkImage. The default CacheManager
// stores cache metadata via a JsonCacheInfoRepository, which does real file
// I/O. Swapping in a cache manager backed by [NonStoringObjectProvider]
// skips that file-backed metadata store entirely (retrieveCacheData just
// returns null, nothing touches the filesystem), so the (mocked by
// flutter_test, always-400) network request fails fast and errorWidget
// builds immediately — nothing here depends on path_provider.
//
// This must be built fresh inside the test body, not reused as a shared
// singleton (there's only one test in this file today, which is the only
// reason a singleton would happen to work — don't copy that pattern if a
// second test is added here). See the comment on CacheManager construction
// below for why it can't be built in setUp() either.
CacheManager _newTestCacheManager() =>
    CacheManager(Config('testImageCache', repo: NonStoringObjectProvider()));

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
      // Must be constructed here, inside the test body — not in setUp()
      // and not cached as a shared singleton. CacheManager's constructor
      // kicks off CacheStore's `config.repo.open().then(...)` future
      // immediately, and that future is bound to whichever Dart zone it
      // was created in. flutter_test runs each test body in its own zone
      // (distinct from setUp()'s zone), so a CacheManager built outside
      // this test body would have its internal future tied to a zone this
      // test's pumpAndSettle() can't service, and it would hang forever
      // waiting on work scheduled in a zone nothing here is pumping.
      CachedNetworkImageProvider.defaultCacheManager = _newTestCacheManager();

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

      // Starts on Home. The NavigationBar always renders all four tab
      // labels regardless of which tab is active (alwaysShow behavior), so
      // asserting on those labels alone can't prove navigation happened —
      // assert on content unique to each screen's own body instead.
      expect(find.text('What would you like to cook?'), findsOneWidget);

      // Discover.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Discover'));
      await tester.pumpAndSettle();
      expect(find.text('2 recipes found'), findsOneWidget);

      // Favorites.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('0 saved recipes'), findsOneWidget);

      // Profile.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Yannick Ouedraogo'), findsOneWidget);

      // The cache manager schedules a 10-second cleanup timer the first
      // time it looks up cache metadata. It must be flushed before the
      // test ends, or flutter_test's "pending timer after dispose"
      // invariant check fails the test.
      await tester.pump(const Duration(seconds: 11));
    },
  );
}
