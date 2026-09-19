class RecipeIngredient {
  const RecipeIngredient({required this.name, required this.quantity, required this.unit});

  final String name;
  final double quantity;
  final String unit;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity, 'unit': unit};
}

class RecipeStep {
  const RecipeStep({required this.title, required this.description, required this.minutes});

  final String title;
  final String description;
  final int minutes;

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        title: json['title'] as String,
        description: json['description'] as String,
        minutes: json['minutes'] as int,
      );

  Map<String, dynamic> toJson() => {'title': title, 'description': description, 'minutes': minutes};
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servings,
    required this.difficulty,
    required this.calories,
    required this.rating,
    required this.ratingCount,
    required this.authorName,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final String difficulty;
  final int calories;
  final double rating;
  final int ratingCount;
  final String authorName;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        imageUrl: json['imageUrl'] as String,
        prepMinutes: json['prepMinutes'] as int,
        cookMinutes: json['cookMinutes'] as int,
        servings: json['servings'] as int,
        difficulty: json['difficulty'] as String,
        calories: json['calories'] as int,
        rating: (json['rating'] as num).toDouble(),
        ratingCount: json['ratingCount'] as int,
        authorName: json['authorName'] as String,
        ingredients: (json['ingredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (json['steps'] as List).map((e) => RecipeStep.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        'prepMinutes': prepMinutes,
        'cookMinutes': cookMinutes,
        'servings': servings,
        'difficulty': difficulty,
        'calories': calories,
        'rating': rating,
        'ratingCount': ratingCount,
        'authorName': authorName,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
      };
}
