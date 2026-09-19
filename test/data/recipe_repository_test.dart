import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/data/recipe_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadRecipes parses all bundled recipes', () async {
    final repository = RecipeRepository();
    final recipes = await repository.loadRecipes();
    expect(recipes, isNotEmpty);
    expect(recipes.any((r) => r.id == 'creamy-garlic-pasta'), isTrue);
  });

  test('loadCategories parses all bundled categories', () async {
    final repository = RecipeRepository();
    final categories = await repository.loadCategories();
    expect(categories, hasLength(7));
    expect(categories.any((c) => c.id == 'Breakfast'), isTrue);
  });
}
