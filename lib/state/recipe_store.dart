import 'package:flutter/widgets.dart';

import '../models/category.dart';
import '../models/recipe.dart';

class RecipeStore extends ChangeNotifier {
  RecipeStore({
    required List<Recipe> initialRecipes,
    required List<Category> categories,
  }) : _recipes = List.of(initialRecipes),
       _categories = List.unmodifiable(categories);

  final List<Recipe> _recipes;
  final List<Category> _categories;
  final Set<String> _favoriteIds = {};

  List<Recipe> get all => List.unmodifiable(_recipes);
  List<Category> get categories => _categories;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  Recipe? get featured {
    if (_recipes.isEmpty) return null;
    final sorted = List<Recipe>.of(_recipes)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.first;
  }

  List<Recipe> get popular {
    final sorted = List<Recipe>.of(_recipes)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }

  List<Recipe> get quickAndEasy {
    final quick = _recipes.where((r) => r.prepMinutes <= 30).toList()
      ..sort((a, b) => a.prepMinutes.compareTo(b.prepMinutes));
    return quick;
  }

  List<Recipe> get favorites =>
      _recipes.where((r) => _favoriteIds.contains(r.id)).toList();

  Recipe? byId(String id) {
    for (final recipe in _recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  List<Recipe> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return _recipes.where((r) => r.title.toLowerCase().contains(q)).toList();
  }

  List<Recipe> byCategory(String categoryId) {
    if (categoryId == 'all') return all;
    return _recipes.where((r) => r.category == categoryId).toList();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  void addRecipe(Recipe recipe) {
    _recipes.insert(0, recipe);
    notifyListeners();
  }
}

class RecipeStoreScope extends InheritedNotifier<RecipeStore> {
  const RecipeStoreScope({
    super.key,
    required RecipeStore store,
    required super.child,
  }) : super(notifier: store);

  static RecipeStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RecipeStoreScope>();
    assert(scope != null, 'No RecipeStoreScope found in context');
    return scope!.notifier!;
  }
}
