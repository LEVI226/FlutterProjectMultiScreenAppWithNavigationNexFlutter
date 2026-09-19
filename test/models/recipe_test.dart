import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/recipe.dart';

void main() {
  group('RecipeIngredient', () {
    test('fromJson/toJson round trip', () {
      final json = {'name': 'Garlic', 'quantity': 3.0, 'unit': 'cloves'};
      final ingredient = RecipeIngredient.fromJson(json);
      expect(ingredient.name, 'Garlic');
      expect(ingredient.quantity, 3.0);
      expect(ingredient.unit, 'cloves');
      expect(ingredient.toJson(), json);
    });
  });

  group('RecipeStep', () {
    test('fromJson/toJson round trip', () {
      final json = {
        'title': 'Boil Pasta',
        'description': 'Cook until al dente.',
        'minutes': 9,
      };
      final step = RecipeStep.fromJson(json);
      expect(step.title, 'Boil Pasta');
      expect(step.minutes, 9);
      expect(step.toJson(), json);
    });
  });

  group('Recipe', () {
    final json = {
      'id': 'r1',
      'title': 'Creamy Garlic Pasta',
      'description': 'A silky Italian comfort dish.',
      'category': 'Dinner',
      'imageUrl':
          'https://images.unsplash.com/photo-1600803907087-f56d462fd26b',
      'prepMinutes': 25,
      'cookMinutes': 15,
      'servings': 2,
      'difficulty': 'Easy',
      'calories': 420,
      'rating': 4.8,
      'ratingCount': 240,
      'authorName': 'Chef Amelia Vance',
      'ingredients': [
        {'name': 'Tagliatelle', 'quantity': 200.0, 'unit': 'g'},
      ],
      'steps': [
        {
          'title': 'Boil Pasta',
          'description': 'Cook until al dente.',
          'minutes': 9,
        },
      ],
    };

    test('fromJson parses nested ingredients and steps', () {
      final recipe = Recipe.fromJson(json);
      expect(recipe.id, 'r1');
      expect(recipe.title, 'Creamy Garlic Pasta');
      expect(recipe.rating, 4.8);
      expect(recipe.ingredients, hasLength(1));
      expect(recipe.ingredients.first.name, 'Tagliatelle');
      expect(recipe.steps, hasLength(1));
      expect(recipe.steps.first.title, 'Boil Pasta');
    });

    test('toJson round trips back to an equivalent map', () {
      final recipe = Recipe.fromJson(json);
      expect(recipe.toJson(), json);
    });
  });
}
