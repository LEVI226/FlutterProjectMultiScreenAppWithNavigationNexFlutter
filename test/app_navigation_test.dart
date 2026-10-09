import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savorly/main.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/state/recipe_store.dart';
import 'package:savorly/state/theme_controller.dart';

// HomeScreen renders recipe images via CachedNetworkImage. The default
// CacheManager stores cache metadata in a JSON file resolved through
// path_provider, which has no platform-channel implementation in the widget
// test environment and never resolves there, so pumpAndSettle() times out
// waiting for the placeholder's spinner to stop. Swapping in a cache manager
// backed by [NonStoringObjectProvider] skips that file-backed metadata store
// entirely, letting the (mocked, always-400) network request fail fast and
// the errorWidget build immediately.
class _TestCacheManager extends CacheManager {
  static final _instance = _TestCacheManager._();

  factory _TestCacheManager() => _instance;

  _TestCacheManager._()
    : super(Config('testImageCache', repo: NonStoringObjectProvider()));
}

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
      // path_provider is also used by the cache manager's file system to
      // locate where downloaded images would be written; mock it so that
      // path resolves instantly instead of hanging on an unanswered
      // platform channel call.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => Directory.systemTemp.path,
          );
      CachedNetworkImageProvider.defaultCacheManager = _TestCacheManager();

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
