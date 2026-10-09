import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/category.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/screens/discover_screen.dart';
import 'package:savorly/state/recipe_store.dart';

// RecipeCard renders its image via CachedNetworkImage. The default
// CacheManager stores cache metadata in a JSON file resolved through
// path_provider, which has no platform-channel implementation in the widget
// test environment and never resolves there, so pumpAndSettle() times out
// waiting for the placeholder's spinner to stop. Swapping in a cache manager
// backed by [NonStoringObjectProvider] skips that file-backed metadata store
// entirely, letting the (mocked, always-400) network request fail fast and
// the errorWidget build immediately.
//
// A fresh CacheManager (with a unique cache key) is built for every test
// rather than reused as a singleton: all the test recipes here share the
// same (empty) imageUrl, and WebHelper's in-flight-request bookkeeping is
// keyed by url, so reusing one instance across tests let a later test's
// image request get stuck subscribed to an already-finished stream left
// over from an earlier test.
int _cacheManagerSeq = 0;

void _mockImageLoading() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => Directory.systemTemp.path,
      );
  CachedNetworkImageProvider.defaultCacheManager = CacheManager(
    Config('testImageCache${_cacheManagerSeq++}', repo: NonStoringObjectProvider()),
  );
}

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

  // The cache manager schedules a 10-second cleanup timer the first time it
  // looks up cache metadata. It must be flushed before the test ends, or
  // flutter_test's "pending timer after dispose" invariant check fails the
  // test.
  Future<void> flushCacheManagerCleanupTimer(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 11));

  testWidgets('shows all recipes by default', (tester) async {
    _mockImageLoading();
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    expect(find.text('Pasta Bolognese'), findsOneWidget);
    expect(find.text('Quick Salad'), findsOneWidget);
    expect(find.text('Pancakes'), findsOneWidget);

    await flushCacheManagerCleanupTimer(tester);
  });

  testWidgets('typing in the search field filters the recipe list', (tester) async {
    _mockImageLoading();
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Pasta');
    await tester.pumpAndSettle();

    expect(find.text('Pasta Bolognese'), findsOneWidget);
    expect(find.text('Quick Salad'), findsNothing);
    expect(find.text('Pancakes'), findsNothing);

    await flushCacheManagerCleanupTimer(tester);
  });

  testWidgets('tapping a category chip filters to that category', (tester) async {
    _mockImageLoading();
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();

    expect(find.text('Quick Salad'), findsOneWidget);
    expect(find.text('Pasta Bolognese'), findsNothing);
    expect(find.text('Pancakes'), findsNothing);

    await flushCacheManagerCleanupTimer(tester);
  });

  testWidgets('tapping the grid-density toggle changes its icon', (tester) async {
    _mockImageLoading();
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.view_module_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Grid density'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.grid_view), findsOneWidget);
    expect(find.byIcon(Icons.view_module_outlined), findsNothing);

    await flushCacheManagerCleanupTimer(tester);
  });
}
