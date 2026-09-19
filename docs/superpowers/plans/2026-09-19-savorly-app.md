# Savorly Flutter App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Savorly Flutter app — a 6-screen recipe browser/manager with GoRouter navigation, light/dark theming, and a form with validation — for the NextFlutter "Multi-screen app with navigation" certification (score ≥ 70/100).

**Architecture:** Flat layered `lib/` structure (theme/router/models/data/state/screens/widgets). A single `RecipeRepository` loads bundled JSON at startup into a `RecipeStore` (ChangeNotifier, exposed via `InheritedNotifier`), which is the single source of truth for recipe data + favorites for the session. `GoRouter` with a `ShellRoute` wraps 4 tab screens in an adaptive nav (`NavigationBar` on mobile, `NavigationRail` on tablet ≥600px); Recipe Detail and Add Recipe are pushed full-screen outside the shell.

**Tech Stack:** Flutter 3.47.3 / Dart 3.13.3 (stable), `go_router`, `google_fonts` (Manrope), `image_picker`, `lints` + `test` (dev).

**Spec:** `docs/superpowers/specs/2026-09-19-recipe-book-app-design.md`

## Global Constraints

- Package name `savorly`, app title "Savorly". Platforms: android, web, windows only (`flutter create --platforms=android,web,windows`) — the three verified working targets on this machine.
- No external state management package (no Provider/Riverpod/Bloc) — `ChangeNotifier` + `InheritedNotifier` only, per the spec.
- No real network/API calls beyond `Image.network` for photos — no backend, no persistence (favorites/added recipes/theme reset each launch).
- Every `Image.network` must have both `loadingBuilder` and `errorBuilder` (spec's "Mobile & platform robustness" section) — never a raw broken-image icon.
- `image_picker` results are `XFile`; preview must be `kIsWeb`-aware (`Image.memory` on web via `readAsBytes()`, `Image.file` elsewhere) — `dart:io File` does not exist on web.
- Forms wrapped in `SingleChildScrollView`; screens with custom chrome respect `SafeArea`.
- Colors: light `ColorScheme` built from exact spec hex values (`primary #A93017`, `secondary #3D692E`, `tertiary #805200`, `surface #F9F9F7`, `error #BA1A1A`); dark `ColorScheme` via `ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark)`. Text via `GoogleFonts.manropeTextTheme`.
- **Deviation from spec (implementation-mechanics only, same outcome):** the broken-image fallback is a `Container` + `Icon(Icons.restaurant)` on a tonal background, not a bundled `assets/images/placeholder.png` binary file — avoids authoring a binary asset by hand, same "never a raw error icon" guarantee. Likewise, no dedicated startup loading screen: `main()` awaits the tiny bundled JSON before `runApp`, and the spec's `CircularProgressIndicator` widget-variety point is satisfied by each image's `loadingBuilder` instead.
- Recipe photo URLs are real, verified `images.unsplash.com/photo-<id>` CDN links (checked live during planning, not placeholders) — see Task 3.

---

### Task 1: Project scaffold

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, default `flutter create` output (`lib/main.dart` will be overwritten in Task 9)
- Modify: none (empty dir except `docs/` and `.git/`)

**Interfaces:**
- Produces: a runnable Flutter project with `go_router`, `google_fonts`, `image_picker` as dependencies and `lints`, `test` as dev dependencies; `assets/data/` and `assets/images/` (unused after the deviation above, but harmless) declared in `pubspec.yaml`.

- [ ] **Step 1: Scaffold the project**

Run from `C:\Users\ulric\Documents\nexTflutter\flutter-project-multi-screen-app`:

```bash
flutter create --project-name savorly --org com.savorly --platforms=android,web,windows .
```

- [ ] **Step 2: Verify the default app builds and analyzes clean**

Run: `flutter analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: the default `widget_test.dart` passes (1 test).

- [ ] **Step 3: Add dependencies**

```bash
flutter pub add go_router google_fonts image_picker
flutter pub add --dev lints
```

(`test` and `flutter_lints`/`lints` may already be present from `flutter create`; `flutter pub add` is idempotent — it just updates the version constraint.)

- [ ] **Step 4: Replace `analysis_options.yaml`**

```yaml
include: package:lints/recommended.yaml

linter:
  rules:
    prefer_single_quotes: true
```

- [ ] **Step 5: Declare asset folders in `pubspec.yaml`**

Add under the existing `flutter:` key:

```yaml
  assets:
    - assets/data/
```

- [ ] **Step 6: Create the data asset folder**

```bash
mkdir -p assets/data
```

- [ ] **Step 7: Verify and commit**

Run: `flutter analyze` — Expected: `No issues found!`

```bash
git add pubspec.yaml pubspec.lock analysis_options.yaml android ios linux macos web windows lib test .metadata .gitignore
git commit -m "Scaffold Flutter project with go_router, google_fonts, image_picker"
```

---

### Task 2: Data models — Recipe, RecipeIngredient, RecipeStep, Category

**Files:**
- Create: `lib/models/recipe.dart`
- Create: `lib/models/category.dart`
- Test: `test/models/recipe_test.dart`
- Test: `test/models/category_test.dart`

**Interfaces:**
- Produces:
  - `class RecipeIngredient { final String name; final double quantity; final String unit; factory .fromJson(Map<String,dynamic>); Map<String,dynamic> toJson(); }`
  - `class RecipeStep { final String title; final String description; final int minutes; factory .fromJson(Map<String,dynamic>); Map<String,dynamic> toJson(); }`
  - `class Recipe { final String id, title, description, category, imageUrl, difficulty, authorName; final int prepMinutes, cookMinutes, servings, calories, ratingCount; final double rating; final List<RecipeIngredient> ingredients; final List<RecipeStep> steps; factory .fromJson(Map<String,dynamic>); Map<String,dynamic> toJson(); }`
  - `class Category { final String id, name, emoji; factory .fromJson(Map<String,dynamic>); }`

- [ ] **Step 1: Write the failing tests**

`test/models/recipe_test.dart`:

```dart
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
      final json = {'title': 'Boil Pasta', 'description': 'Cook until al dente.', 'minutes': 9};
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
      'imageUrl': 'https://images.unsplash.com/photo-1600803907087-f56d462fd26b',
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
        {'title': 'Boil Pasta', 'description': 'Cook until al dente.', 'minutes': 9},
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
```

`test/models/category_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/category.dart';

void main() {
  test('Category.fromJson parses id, name, emoji', () {
    final category = Category.fromJson({'id': 'Breakfast', 'name': 'Breakfast', 'emoji': '🥞'});
    expect(category.id, 'Breakfast');
    expect(category.name, 'Breakfast');
    expect(category.emoji, '🥞');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/models/` — Expected: FAIL (`Target of URI doesn't exist: 'package:savorly/models/recipe.dart'`).

- [ ] **Step 3: Implement `lib/models/category.dart`**

```dart
class Category {
  const Category({required this.id, required this.name, required this.emoji});

  final String id;
  final String name;
  final String emoji;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
      );
}
```

- [ ] **Step 4: Implement `lib/models/recipe.dart`**

```dart
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/models/` — Expected: all 4 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/models test/models
git commit -m "Add Recipe, RecipeIngredient, RecipeStep, Category models"
```

---

### Task 3: Recipe & category JSON data + RecipeRepository

**Files:**
- Create: `assets/data/recipes.json`
- Create: `assets/data/categories.json`
- Create: `lib/data/recipe_repository.dart`
- Test: `test/data/recipe_repository_test.dart`

**Interfaces:**
- Consumes: `Recipe.fromJson`, `Category.fromJson` (Task 2)
- Produces: `class RecipeRepository { Future<List<Recipe>> loadRecipes(); Future<List<Category>> loadCategories(); }`

- [ ] **Step 1: Write `assets/data/categories.json`**

```json
[
  {"id": "Breakfast", "name": "Breakfast", "emoji": "🥞"},
  {"id": "Lunch", "name": "Lunch", "emoji": "🥗"},
  {"id": "Dinner", "name": "Dinner", "emoji": "🍲"},
  {"id": "Dessert", "name": "Dessert", "emoji": "🍰"},
  {"id": "Healthy", "name": "Healthy", "emoji": "🥑"},
  {"id": "Vegan", "name": "Vegan", "emoji": "🌱"},
  {"id": "Drinks", "name": "Drinks", "emoji": "🍹"}
]
```

- [ ] **Step 2: Write `assets/data/recipes.json`**

All 15 photo URLs below are real `images.unsplash.com` CDN links, verified reachable while writing this plan (2026-09-19). Each uses the `?w=800&q=80&auto=format&fit=crop` suffix for a reasonably-sized, cropped image.

```json
[
  {
    "id": "creamy-garlic-pasta",
    "title": "Creamy Garlic Pasta",
    "description": "A quick, silky Italian comfort dish with sautéed garlic, heavy cream, freshly grated parmesan, and al dente pasta.",
    "category": "Dinner",
    "imageUrl": "https://images.unsplash.com/photo-1600803907087-f56d462fd26b?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 25,
    "cookMinutes": 15,
    "servings": 2,
    "difficulty": "Easy",
    "calories": 420,
    "rating": 4.8,
    "ratingCount": 240,
    "authorName": "Chef Amelia Vance",
    "ingredients": [
      {"name": "Tagliatelle or spaghetti", "quantity": 200, "unit": "g"},
      {"name": "Garlic cloves", "quantity": 3, "unit": "cloves"},
      {"name": "Heavy cooking cream", "quantity": 120, "unit": "ml"},
      {"name": "Parmigiano-Reggiano", "quantity": 50, "unit": "g"},
      {"name": "Extra virgin olive oil", "quantity": 2, "unit": "tbsp"},
      {"name": "Sea salt & black pepper", "quantity": 1, "unit": "to taste"}
    ],
    "steps": [
      {"title": "Boil Pasta", "description": "Boil salted water and cook pasta al dente (8-9 min). Reserve 1/2 cup starchy pasta water before draining.", "minutes": 9},
      {"title": "Sauté Aromatics", "description": "Sauté sliced garlic gently in olive oil until fragrant and pale golden, avoiding browning.", "minutes": 2},
      {"title": "Emulsify Sauce", "description": "Stir in cream and grated parmesan until smooth, then toss the drained hot pasta through the pan.", "minutes": 3}
    ]
  },
  {
    "id": "grilled-chicken-bowl",
    "title": "Grilled Chicken Bowl",
    "description": "Grilled chicken breast over quinoa with avocado, cherry tomatoes, and a tahini drizzle.",
    "category": "Lunch",
    "imageUrl": "https://images.unsplash.com/photo-1788090485545-26c4d90f9c9f?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 15,
    "cookMinutes": 15,
    "servings": 2,
    "difficulty": "Medium",
    "calories": 480,
    "rating": 4.7,
    "ratingCount": 312,
    "authorName": "Chef Marcus Lee",
    "ingredients": [
      {"name": "Chicken breast", "quantity": 2, "unit": "pieces"},
      {"name": "Cooked quinoa", "quantity": 300, "unit": "g"},
      {"name": "Avocado", "quantity": 1, "unit": "sliced"},
      {"name": "Cherry tomatoes", "quantity": 10, "unit": "halved"},
      {"name": "Tahini", "quantity": 2, "unit": "tbsp"}
    ],
    "steps": [
      {"title": "Grill Chicken", "description": "Season chicken breast and grill 6-7 minutes per side until cooked through.", "minutes": 14},
      {"title": "Assemble Bowl", "description": "Layer quinoa, sliced chicken, avocado, and tomatoes in a bowl.", "minutes": 5},
      {"title": "Drizzle & Serve", "description": "Drizzle with tahini and serve warm.", "minutes": 1}
    ]
  },
  {
    "id": "avocado-toast-egg",
    "title": "Avocado Toast & Egg",
    "description": "Toasted sourdough topped with smashed avocado, a soft poached egg, and chili flakes.",
    "category": "Breakfast",
    "imageUrl": "https://images.unsplash.com/photo-1687276287139-88f7333c8ca4?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 10,
    "cookMinutes": 5,
    "servings": 1,
    "difficulty": "Easy",
    "calories": 320,
    "rating": 4.9,
    "ratingCount": 189,
    "authorName": "Chef Amelia Vance",
    "ingredients": [
      {"name": "Sourdough bread", "quantity": 2, "unit": "slices"},
      {"name": "Avocado", "quantity": 1, "unit": "whole"},
      {"name": "Egg", "quantity": 1, "unit": "whole"},
      {"name": "Chili flakes", "quantity": 1, "unit": "pinch"}
    ],
    "steps": [
      {"title": "Toast Bread", "description": "Toast sourdough slices until golden and crisp.", "minutes": 3},
      {"title": "Poach Egg", "description": "Poach the egg in gently simmering water for 3 minutes.", "minutes": 3},
      {"title": "Assemble", "description": "Smash avocado onto toast, top with the poached egg and chili flakes.", "minutes": 2}
    ]
  },
  {
    "id": "spicy-miso-ramen",
    "title": "Spicy Miso Ramen",
    "description": "Steaming ramen noodles in a spicy miso broth with chashu pork, bamboo shoots, and a marinated egg.",
    "category": "Dinner",
    "imageUrl": "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 15,
    "cookMinutes": 25,
    "servings": 2,
    "difficulty": "Hard",
    "calories": 620,
    "rating": 4.8,
    "ratingCount": 156,
    "authorName": "Chef Haruto Sato",
    "ingredients": [
      {"name": "Ramen noodles", "quantity": 2, "unit": "portions"},
      {"name": "Miso paste", "quantity": 3, "unit": "tbsp"},
      {"name": "Chashu pork", "quantity": 150, "unit": "g"},
      {"name": "Marinated egg", "quantity": 2, "unit": "whole"},
      {"name": "Chili oil", "quantity": 1, "unit": "tbsp"}
    ],
    "steps": [
      {"title": "Prepare Broth", "description": "Simmer stock with miso paste until dissolved and fragrant.", "minutes": 15},
      {"title": "Cook Noodles", "description": "Cook ramen noodles according to package instructions.", "minutes": 4},
      {"title": "Assemble Bowl", "description": "Combine noodles and broth, top with chashu, egg, and chili oil.", "minutes": 3}
    ]
  },
  {
    "id": "chocolate-pancakes",
    "title": "Chocolate Pancakes",
    "description": "Fluffy chocolate pancakes stacked high with melted dark chocolate sauce and fresh raspberries.",
    "category": "Dessert",
    "imageUrl": "https://images.unsplash.com/photo-1597699401474-e8714c1b7879?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 10,
    "cookMinutes": 10,
    "servings": 3,
    "difficulty": "Easy",
    "calories": 410,
    "rating": 4.6,
    "ratingCount": 98,
    "authorName": "Chef Elena Rostova",
    "ingredients": [
      {"name": "Flour", "quantity": 200, "unit": "g"},
      {"name": "Cocoa powder", "quantity": 30, "unit": "g"},
      {"name": "Milk", "quantity": 250, "unit": "ml"},
      {"name": "Dark chocolate", "quantity": 80, "unit": "g"},
      {"name": "Raspberries", "quantity": 100, "unit": "g"}
    ],
    "steps": [
      {"title": "Make Batter", "description": "Whisk flour, cocoa powder, and milk into a smooth batter.", "minutes": 5},
      {"title": "Cook Pancakes", "description": "Cook batter in a hot pan, 2 minutes per side, until fluffy.", "minutes": 8},
      {"title": "Top & Serve", "description": "Stack pancakes, drizzle with melted chocolate, and top with raspberries.", "minutes": 2}
    ]
  },
  {
    "id": "mediterranean-salad",
    "title": "15-min Mediterranean Salad",
    "description": "A fresh salad of cucumber ribbons, olives, tomatoes, and feta bathed in olive oil.",
    "category": "Healthy",
    "imageUrl": "https://images.unsplash.com/photo-1606735584785-1848fdcaea57?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 15,
    "cookMinutes": 0,
    "servings": 2,
    "difficulty": "Easy",
    "calories": 280,
    "rating": 4.9,
    "ratingCount": 850,
    "authorName": "Chef Sofia Nikolaou",
    "ingredients": [
      {"name": "Cucumber", "quantity": 1, "unit": "whole"},
      {"name": "Kalamata olives", "quantity": 60, "unit": "g"},
      {"name": "Cherry tomatoes", "quantity": 10, "unit": "halved"},
      {"name": "Feta cheese", "quantity": 100, "unit": "g"},
      {"name": "Olive oil", "quantity": 2, "unit": "tbsp"}
    ],
    "steps": [
      {"title": "Prep Vegetables", "description": "Ribbon the cucumber and halve the tomatoes.", "minutes": 8},
      {"title": "Combine & Dress", "description": "Toss vegetables with olives, feta, and olive oil.", "minutes": 5},
      {"title": "Season & Serve", "description": "Season with oregano and serve immediately.", "minutes": 2}
    ]
  },
  {
    "id": "garlic-butter-salmon",
    "title": "Garlic Butter Salmon",
    "description": "Pan-seared salmon fillet basted with garlic herb butter, thyme, and lemon.",
    "category": "Dinner",
    "imageUrl": "https://images.unsplash.com/photo-1499125562588-29fb8a56b5d5?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 10,
    "cookMinutes": 10,
    "servings": 2,
    "difficulty": "Easy",
    "calories": 450,
    "rating": 4.8,
    "ratingCount": 1400,
    "authorName": "Chef Marcus Lee",
    "ingredients": [
      {"name": "Salmon fillets", "quantity": 2, "unit": "pieces"},
      {"name": "Butter", "quantity": 40, "unit": "g"},
      {"name": "Garlic cloves", "quantity": 2, "unit": "cloves"},
      {"name": "Thyme sprigs", "quantity": 2, "unit": "sprigs"},
      {"name": "Lemon", "quantity": 1, "unit": "sliced"}
    ],
    "steps": [
      {"title": "Sear Salmon", "description": "Sear salmon skin-side down in a hot skillet for 5 minutes.", "minutes": 5},
      {"title": "Baste with Butter", "description": "Flip, add butter, garlic, and thyme, and baste continuously.", "minutes": 4},
      {"title": "Rest & Serve", "description": "Rest briefly, then serve with lemon slices.", "minutes": 1}
    ]
  },
  {
    "id": "chicken-teriyaki-bowl",
    "title": "Chicken Teriyaki Bowl",
    "description": "Charred glazed chicken over steamed rice with sesame seeds, broccoli, and scallions.",
    "category": "Dinner",
    "imageUrl": "https://images.unsplash.com/photo-1788090485550-ca71c6d578fb?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 15,
    "cookMinutes": 15,
    "servings": 2,
    "difficulty": "Medium",
    "calories": 540,
    "rating": 4.7,
    "ratingCount": 210,
    "authorName": "Chef Haruto Sato",
    "ingredients": [
      {"name": "Chicken thighs", "quantity": 300, "unit": "g"},
      {"name": "Teriyaki sauce", "quantity": 80, "unit": "ml"},
      {"name": "Steamed rice", "quantity": 300, "unit": "g"},
      {"name": "Broccoli florets", "quantity": 150, "unit": "g"},
      {"name": "Sesame seeds", "quantity": 1, "unit": "tbsp"}
    ],
    "steps": [
      {"title": "Cook Chicken", "description": "Sear chicken thighs until browned, then glaze with teriyaki sauce.", "minutes": 12},
      {"title": "Steam Broccoli", "description": "Steam broccoli florets until tender-crisp.", "minutes": 5},
      {"title": "Assemble Bowl", "description": "Serve sliced chicken and broccoli over rice, topped with sesame seeds.", "minutes": 3}
    ]
  },
  {
    "id": "creamy-mushroom-risotto",
    "title": "Creamy Mushroom Risotto",
    "description": "Earthy arborio rice risotto with sautéed wild mushrooms and aged parmigiano-reggiano.",
    "category": "Dinner",
    "imageUrl": "https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 10,
    "cookMinutes": 25,
    "servings": 3,
    "difficulty": "Medium",
    "calories": 510,
    "rating": 4.9,
    "ratingCount": 175,
    "authorName": "Chef Amelia Vance",
    "ingredients": [
      {"name": "Arborio rice", "quantity": 250, "unit": "g"},
      {"name": "Mixed wild mushrooms", "quantity": 200, "unit": "g"},
      {"name": "Vegetable stock", "quantity": 1, "unit": "liter"},
      {"name": "Parmigiano-Reggiano", "quantity": 60, "unit": "g"},
      {"name": "White wine", "quantity": 100, "unit": "ml"}
    ],
    "steps": [
      {"title": "Sauté Mushrooms", "description": "Sauté mushrooms until golden, then set aside.", "minutes": 6},
      {"title": "Toast & Deglaze Rice", "description": "Toast rice, deglaze with wine, then add hot stock gradually while stirring.", "minutes": 18},
      {"title": "Finish Risotto", "description": "Stir in parmesan and mushrooms, then serve immediately.", "minutes": 2}
    ]
  },
  {
    "id": "berry-acai-smoothie-bowl",
    "title": "Berry Acai Smoothie Bowl",
    "description": "Deep purple açai smoothie bowl topped with blueberries, strawberries, coconut, and granola.",
    "category": "Breakfast",
    "imageUrl": "https://images.unsplash.com/photo-1627308594190-a057cd4bfac8?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 10,
    "cookMinutes": 0,
    "servings": 1,
    "difficulty": "Easy",
    "calories": 350,
    "rating": 4.8,
    "ratingCount": 430,
    "authorName": "Chef Sofia Nikolaou",
    "ingredients": [
      {"name": "Frozen açai puree", "quantity": 100, "unit": "g"},
      {"name": "Banana", "quantity": 1, "unit": "whole"},
      {"name": "Blueberries", "quantity": 40, "unit": "g"},
      {"name": "Granola", "quantity": 30, "unit": "g"},
      {"name": "Coconut flakes", "quantity": 10, "unit": "g"}
    ],
    "steps": [
      {"title": "Blend Base", "description": "Blend açai puree with banana until thick and smooth.", "minutes": 5},
      {"title": "Pour & Top", "description": "Pour into a bowl and arrange blueberries, granola, and coconut on top.", "minutes": 5}
    ]
  },
  {
    "id": "artisan-sourdough-pizza",
    "title": "Artisan Sourdough Pizza",
    "description": "Wood-fired-style sourdough pizza with San Marzano tomato sauce, buffalo mozzarella, and basil.",
    "category": "Lunch",
    "imageUrl": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 20,
    "cookMinutes": 25,
    "servings": 4,
    "difficulty": "Hard",
    "calories": 590,
    "rating": 4.6,
    "ratingCount": 267,
    "authorName": "Chef Elena Rostova",
    "ingredients": [
      {"name": "Sourdough pizza base", "quantity": 1, "unit": "whole"},
      {"name": "San Marzano tomato sauce", "quantity": 150, "unit": "g"},
      {"name": "Buffalo mozzarella", "quantity": 150, "unit": "g"},
      {"name": "Fresh basil", "quantity": 10, "unit": "leaves"},
      {"name": "Olive oil", "quantity": 1, "unit": "tbsp"}
    ],
    "steps": [
      {"title": "Prepare Base", "description": "Spread tomato sauce evenly over the sourdough base.", "minutes": 5},
      {"title": "Add Toppings", "description": "Tear mozzarella over the sauce and drizzle with olive oil.", "minutes": 5},
      {"title": "Bake", "description": "Bake at maximum oven temperature until the crust is blistered and cheese is bubbling.", "minutes": 12},
      {"title": "Finish", "description": "Top with fresh basil leaves before serving.", "minutes": 3}
    ]
  },
  {
    "id": "matcha-green-tea-crepes",
    "title": "Matcha Green Tea Crepes",
    "description": "Delicate stacked matcha mille crepes layered with whipped vanilla cream.",
    "category": "Dessert",
    "imageUrl": "https://images.unsplash.com/photo-1656057205408-4a0a62cf2dfb?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 20,
    "cookMinutes": 5,
    "servings": 4,
    "difficulty": "Easy",
    "calories": 380,
    "rating": 4.5,
    "ratingCount": 112,
    "authorName": "Chef Haruto Sato",
    "ingredients": [
      {"name": "Flour", "quantity": 150, "unit": "g"},
      {"name": "Matcha powder", "quantity": 10, "unit": "g"},
      {"name": "Milk", "quantity": 300, "unit": "ml"},
      {"name": "Whipped cream", "quantity": 200, "unit": "g"},
      {"name": "Eggs", "quantity": 2, "unit": "whole"}
    ],
    "steps": [
      {"title": "Make Batter", "description": "Whisk flour, matcha powder, milk, and eggs into a thin batter.", "minutes": 5},
      {"title": "Cook Crepes", "description": "Cook thin crepes one at a time in a hot non-stick pan.", "minutes": 12},
      {"title": "Layer & Chill", "description": "Layer crepes with whipped cream and chill before slicing.", "minutes": 3}
    ]
  },
  {
    "id": "greek-quinoa-salad",
    "title": "Greek Quinoa Salad",
    "description": "Crisp tri-color quinoa salad with cucumber, tomatoes, olives, and feta in a lemon herb dressing.",
    "category": "Healthy",
    "imageUrl": "https://images.unsplash.com/photo-1599021419847-d8a7a6aba5b4?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 15,
    "cookMinutes": 0,
    "servings": 2,
    "difficulty": "Easy",
    "calories": 340,
    "rating": 4.7,
    "ratingCount": 198,
    "authorName": "Chef Sofia Nikolaou",
    "ingredients": [
      {"name": "Cooked quinoa", "quantity": 250, "unit": "g"},
      {"name": "Cucumber", "quantity": 1, "unit": "diced"},
      {"name": "Cherry tomatoes", "quantity": 10, "unit": "halved"},
      {"name": "Kalamata olives", "quantity": 50, "unit": "g"},
      {"name": "Feta cheese", "quantity": 80, "unit": "g"}
    ],
    "steps": [
      {"title": "Prep Vegetables", "description": "Dice cucumber and halve the cherry tomatoes.", "minutes": 8},
      {"title": "Combine & Dress", "description": "Toss quinoa with vegetables, olives, feta, and lemon dressing.", "minutes": 5},
      {"title": "Chill & Serve", "description": "Chill briefly before serving for best flavor.", "minutes": 2}
    ]
  },
  {
    "id": "vegan-buddha-bowl",
    "title": "Vegan Buddha Bowl",
    "description": "A colorful bowl of roasted chickpeas, sweet potato, kale, and tahini dressing.",
    "category": "Vegan",
    "imageUrl": "https://images.unsplash.com/photo-1505576633757-0ac1084af824?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 15,
    "cookMinutes": 25,
    "servings": 2,
    "difficulty": "Medium",
    "calories": 460,
    "rating": 4.7,
    "ratingCount": 145,
    "authorName": "Chef Marcus Lee",
    "ingredients": [
      {"name": "Chickpeas", "quantity": 240, "unit": "g"},
      {"name": "Sweet potato", "quantity": 1, "unit": "whole"},
      {"name": "Kale", "quantity": 80, "unit": "g"},
      {"name": "Tahini", "quantity": 2, "unit": "tbsp"},
      {"name": "Lemon juice", "quantity": 1, "unit": "tbsp"}
    ],
    "steps": [
      {"title": "Roast Vegetables", "description": "Roast cubed sweet potato and chickpeas at 200°C until crisp.", "minutes": 22},
      {"title": "Massage Kale", "description": "Massage kale with a little olive oil and lemon juice.", "minutes": 3},
      {"title": "Assemble Bowl", "description": "Combine everything in a bowl and drizzle with tahini dressing.", "minutes": 3}
    ]
  },
  {
    "id": "iced-matcha-latte",
    "title": "Iced Matcha Latte",
    "description": "A refreshing iced latte whisked from ceremonial-grade matcha and chilled oat milk.",
    "category": "Drinks",
    "imageUrl": "https://images.unsplash.com/photo-1717398804885-a6c22b3e5c2f?w=800&q=80&auto=format&fit=crop",
    "prepMinutes": 5,
    "cookMinutes": 0,
    "servings": 1,
    "difficulty": "Easy",
    "calories": 120,
    "rating": 4.6,
    "ratingCount": 88,
    "authorName": "Chef Sofia Nikolaou",
    "ingredients": [
      {"name": "Matcha powder", "quantity": 2, "unit": "g"},
      {"name": "Hot water", "quantity": 60, "unit": "ml"},
      {"name": "Oat milk", "quantity": 200, "unit": "ml"},
      {"name": "Ice cubes", "quantity": 6, "unit": "cubes"}
    ],
    "steps": [
      {"title": "Whisk Matcha", "description": "Whisk matcha powder with hot water until smooth and frothy.", "minutes": 2},
      {"title": "Pour & Serve", "description": "Pour over ice and top with chilled oat milk.", "minutes": 2}
    ]
  }
]
```

- [ ] **Step 3: Write the failing test `test/data/recipe_repository_test.dart`**

```dart
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
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/data/` — Expected: FAIL (`recipe_repository.dart` doesn't exist).

- [ ] **Step 5: Implement `lib/data/recipe_repository.dart`**

```dart
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/category.dart';
import '../models/recipe.dart';

class RecipeRepository {
  Future<List<Recipe>> loadRecipes() async {
    final raw = await rootBundle.loadString('assets/data/recipes.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Category>> loadCategories() async {
    final raw = await rootBundle.loadString('assets/data/categories.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/data/` — Expected: both tests PASS.

- [ ] **Step 7: Commit**

```bash
git add assets/data lib/data test/data
git commit -m "Add recipe/category JSON data and RecipeRepository"
```

---

### Task 4: RecipeStore and ThemeController state

**Files:**
- Create: `lib/state/recipe_store.dart`
- Create: `lib/state/theme_controller.dart`
- Test: `test/state/recipe_store_test.dart`
- Test: `test/state/theme_controller_test.dart`

**Interfaces:**
- Consumes: `Recipe`, `Category` (Task 2)
- Produces:
  - `class RecipeStore extends ChangeNotifier { RecipeStore({required List<Recipe> initialRecipes, required List<Category> categories}); List<Recipe> get all; List<Category> get categories; Recipe? get featured; List<Recipe> get popular; List<Recipe> get quickAndEasy; List<Recipe> get favorites; Recipe? byId(String id); List<Recipe> search(String query); List<Recipe> byCategory(String categoryId); bool isFavorite(String id); void toggleFavorite(String id); void addRecipe(Recipe recipe); }`
  - `class RecipeStoreScope extends InheritedNotifier<RecipeStore> { static RecipeStore of(BuildContext context); }`
  - `class ThemeController extends ChangeNotifier { ThemeMode get mode; void toggle(); }`
  - `class ThemeControllerScope extends InheritedNotifier<ThemeController> { static ThemeController of(BuildContext context); }`

- [ ] **Step 1: Write the failing test `test/state/recipe_store_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/category.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/state/recipe_store.dart';

Recipe _recipe(String id, {String category = 'Dinner', int prepMinutes = 20, double rating = 4.0}) {
  return Recipe(
    id: id,
    title: 'Recipe $id',
    description: 'desc',
    category: category,
    imageUrl: 'https://images.unsplash.com/photo-test',
    prepMinutes: prepMinutes,
    cookMinutes: 10,
    servings: 2,
    difficulty: 'Easy',
    calories: 300,
    rating: rating,
    ratingCount: 10,
    authorName: 'Chef Test',
    ingredients: const [],
    steps: const [],
  );
}

void main() {
  late RecipeStore store;

  setUp(() {
    store = RecipeStore(
      initialRecipes: [
        _recipe('a', category: 'Dinner', prepMinutes: 45, rating: 4.9),
        _recipe('b', category: 'Breakfast', prepMinutes: 10, rating: 4.2),
        _recipe('c', category: 'Dinner', prepMinutes: 20, rating: 4.5),
      ],
      categories: const [Category(id: 'Dinner', name: 'Dinner', emoji: '🍲')],
    );
  });

  test('featured returns the highest-rated recipe', () {
    expect(store.featured?.id, 'a');
  });

  test('quickAndEasy only includes recipes with prepMinutes <= 30', () {
    expect(store.quickAndEasy.map((r) => r.id), containsAll(['b', 'c']));
    expect(store.quickAndEasy.map((r) => r.id), isNot(contains('a')));
  });

  test('byCategory filters by category id', () {
    expect(store.byCategory('Dinner').map((r) => r.id), containsAll(['a', 'c']));
    expect(store.byCategory('Dinner'), hasLength(2));
  });

  test('search matches by title (case-insensitive)', () {
    expect(store.search('RECIPE A').map((r) => r.id), ['a']);
    expect(store.search(''), hasLength(3));
  });

  test('toggleFavorite adds then removes and notifies listeners', () {
    var notifications = 0;
    store.addListener(() => notifications++);

    store.toggleFavorite('a');
    expect(store.isFavorite('a'), isTrue);
    expect(store.favorites.map((r) => r.id), ['a']);

    store.toggleFavorite('a');
    expect(store.isFavorite('a'), isFalse);
    expect(store.favorites, isEmpty);

    expect(notifications, 2);
  });

  test('addRecipe inserts the new recipe and notifies listeners', () {
    var notified = false;
    store.addListener(() => notified = true);

    store.addRecipe(_recipe('new'));

    expect(store.all.map((r) => r.id), contains('new'));
    expect(notified, isTrue);
  });
}
```

- [ ] **Step 2: Write the failing test `test/state/theme_controller_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/state/theme_controller.dart';

void main() {
  test('toggle switches between light and dark, defaults from system', () {
    final controller = ThemeController();
    expect(controller.mode, ThemeMode.system);

    controller.toggle();
    expect(controller.mode, ThemeMode.dark);

    controller.toggle();
    expect(controller.mode, ThemeMode.light);
  });

  test('toggle notifies listeners', () {
    final controller = ThemeController();
    var notified = false;
    controller.addListener(() => notified = true);

    controller.toggle();

    expect(notified, isTrue);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/state/` — Expected: FAIL (files don't exist).

- [ ] **Step 4: Implement `lib/state/recipe_store.dart`**

```dart
import 'package:flutter/widgets.dart';

import '../models/category.dart';
import '../models/recipe.dart';

class RecipeStore extends ChangeNotifier {
  RecipeStore({required List<Recipe> initialRecipes, required List<Category> categories})
      : _recipes = List.of(initialRecipes),
        _categories = List.unmodifiable(categories);

  final List<Recipe> _recipes;
  final List<Category> _categories;
  final Set<String> _favoriteIds = {};

  List<Recipe> get all => List.unmodifiable(_recipes);
  List<Category> get categories => _categories;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  Recipe? get featured {
    if (_recipes.isEmpty) return null;
    final sorted = List<Recipe>.of(_recipes)..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.first;
  }

  List<Recipe> get popular {
    final sorted = List<Recipe>.of(_recipes)..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }

  List<Recipe> get quickAndEasy {
    final quick = _recipes.where((r) => r.prepMinutes <= 30).toList()
      ..sort((a, b) => a.prepMinutes.compareTo(b.prepMinutes));
    return quick;
  }

  List<Recipe> get favorites => _recipes.where((r) => _favoriteIds.contains(r.id)).toList();

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
  const RecipeStoreScope({super.key, required RecipeStore store, required super.child}) : super(notifier: store);

  static RecipeStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RecipeStoreScope>();
    assert(scope != null, 'No RecipeStoreScope found in context');
    return scope!.notifier!;
  }
}
```

- [ ] **Step 5: Implement `lib/state/theme_controller.dart`**

```dart
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({super.key, required ThemeController controller, required super.child})
      : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'No ThemeControllerScope found in context');
    return scope!.notifier!;
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/state/` — Expected: all tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/state test/state
git commit -m "Add RecipeStore and ThemeController with InheritedNotifier scopes"
```

---

### Task 5: App theme (light/dark ColorScheme + Manrope text theme)

**Files:**
- Create: `lib/theme/app_theme.dart`

**Interfaces:**
- Produces: `class AppTheme { static ThemeData light(); static ThemeData dark(); }`

No dedicated unit test (pure declarative `ThemeData` construction, visually verified when screens render in later tasks) — verified via `flutter analyze` only, per the spec's "pragmatic coverage" testing scope.

- [ ] **Step 1: Implement `lib/theme/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const primary = Color(0xFFA93017);
  static const secondary = Color(0xFF3D692E);
  static const tertiary = Color(0xFF805200);
  static const surface = Color(0xFFF9F9F7);
  static const error = Color(0xFFBA1A1A);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      error: error,
    );
    return _themeFrom(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark);
    return _themeFrom(colorScheme);
  }

  static ThemeData _themeFrom(ColorScheme colorScheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it analyzes clean**

Run: `flutter analyze` — Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/theme
git commit -m "Add AppTheme with Savorly light/dark ColorScheme and Manrope text theme"
```

---

### Task 6: Shared widgets — CategoryChip and SectionHeader

**Files:**
- Create: `lib/widgets/category_chip.dart`
- Create: `lib/widgets/section_header.dart`

**Interfaces:**
- Produces:
  - `class CategoryChip extends StatelessWidget { const CategoryChip({required String label, required bool selected, required VoidCallback onTap, String? emoji}); }`
  - `class SectionHeader extends StatelessWidget { const SectionHeader({required IconData icon, required String title, String? subtitle, Widget? trailing}); }`

No dedicated unit tests — simple, purely presentational `StatelessWidget`s reused by later screens/widgets, which do carry tests (Task 7). Verified via `flutter analyze` and visual check once used in Task 11+.

- [ ] **Step 1: Implement `lib/widgets/category_chip.dart`**

```dart
import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, required this.selected, required this.onTap, this.emoji});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement `lib/widgets/section_header.dart`**

```dart
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.title, this.subtitle, this.trailing});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (subtitle != null)
                Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
```

- [ ] **Step 3: Verify and commit**

Run: `flutter analyze` — Expected: `No issues found!`

```bash
git add lib/widgets
git commit -m "Add CategoryChip and SectionHeader shared widgets"
```

---

### Task 7: RecipeCard widget (TDD)

**Files:**
- Create: `lib/widgets/recipe_card.dart`
- Test: `test/widgets/recipe_card_test.dart`

**Interfaces:**
- Consumes: `Recipe` (Task 2)
- Produces: `class RecipeCard extends StatelessWidget { const RecipeCard({required Recipe recipe, required bool isFavorite, required VoidCallback onTap, required VoidCallback onFavoriteToggle}); }`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/recipe.dart';
import 'package:savorly/widgets/recipe_card.dart';

Recipe _testRecipe() => const Recipe(
      id: 'r1',
      title: 'Test Pasta',
      description: 'desc',
      category: 'Dinner',
      imageUrl: 'https://images.unsplash.com/photo-test',
      prepMinutes: 20,
      cookMinutes: 10,
      servings: 2,
      difficulty: 'Easy',
      calories: 400,
      rating: 4.5,
      ratingCount: 10,
      authorName: 'Chef Test',
      ingredients: [],
      steps: [],
    );

void main() {
  testWidgets('shows title, category badge, and an outlined heart when not favorited', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecipeCard(recipe: _testRecipe(), isFavorite: false, onTap: () {}, onFavoriteToggle: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Test Pasta'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('shows a filled heart when favorited and calls onFavoriteToggle on tap', (tester) async {
    var toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecipeCard(
            recipe: _testRecipe(),
            isFavorite: true,
            onTap: () {},
            onFavoriteToggle: () => toggled = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite));
    expect(toggled, isTrue);
  });

  testWidgets('calls onTap when the card is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecipeCard(recipe: _testRecipe(), isFavorite: false, onTap: () => tapped = true, onFavoriteToggle: () {}),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Test Pasta'));
    expect(tapped, isTrue);
  });
}
```

Note: `tester.pump()` (not `pumpAndSettle()`) is used deliberately — `Image.network` triggers a real HTTP request with no network available in the test sandbox, which resolves into the `errorBuilder` path; `pumpAndSettle()` would otherwise wait indefinitely. The tests never assert on the image itself.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/recipe_card_test.dart` — Expected: FAIL (`recipe_card.dart` doesn't exist).

- [ ] **Step 3: Implement `lib/widgets/recipe_card.dart`**

```dart
import 'package:flutter/material.dart';

import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return ColoredBox(
                        color: colorScheme.surfaceContainerHigh,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.restaurant, color: colorScheme.onSurfaceVariant, size: 32),
                    ),
                  ),
                  Positioned(top: 8, left: 8, child: _Badge(text: recipe.category)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavoriteButton(isFavorite: isFavorite, onTap: onFavoriteToggle),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${recipe.prepMinutes} min', style: textTheme.labelSmall),
                      const Spacer(),
                      Text(recipe.difficulty, style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: colorScheme.surface.withValues(alpha: 0.9), shape: BoxShape.circle),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFavorite ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/recipe_card_test.dart` — Expected: all 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/recipe_card.dart test/widgets
git commit -m "Add RecipeCard widget with favorite toggle and image fallback"
```

---

### Task 8: FeaturedRecipeCard and QuickRecipeTile widgets

**Files:**
- Create: `lib/widgets/featured_recipe_card.dart`
- Create: `lib/widgets/quick_recipe_tile.dart`

**Interfaces:**
- Consumes: `Recipe` (Task 2)
- Produces:
  - `class FeaturedRecipeCard extends StatelessWidget { const FeaturedRecipeCard({required Recipe recipe, required VoidCallback onTap}); }`
  - `class QuickRecipeTile extends StatelessWidget { const QuickRecipeTile({required Recipe recipe, required VoidCallback onTap}); }`

No dedicated unit tests (same visual-card family as `RecipeCard`, which already carries the widget-test pattern for this app per spec scope) — verified via `flutter analyze` and manual check in Task 11.

- [ ] **Step 1: Implement `lib/widgets/featured_recipe_card.dart`**

```dart
import 'package:flutter/material.dart';

import '../models/recipe.dart';

class FeaturedRecipeCard extends StatelessWidget {
  const FeaturedRecipeCard({super.key, required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : ColoredBox(color: colorScheme.surfaceContainerHigh),
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.restaurant, color: colorScheme.onSurfaceVariant, size: 40),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      recipe.title,
                      style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.star, size: 16, color: colorScheme.tertiary),
                  const SizedBox(width: 4),
                  Text('${recipe.rating}', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Icon(Icons.schedule, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${recipe.prepMinutes} min', style: textTheme.labelMedium),
                  const Spacer(),
                  FilledButton(onPressed: onTap, child: const Text('View Recipe')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement `lib/widgets/quick_recipe_tile.dart`**

```dart
import 'package:flutter/material.dart';

import '../models/recipe.dart';

class QuickRecipeTile extends StatelessWidget {
  const QuickRecipeTile({super.key, required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : ColoredBox(color: colorScheme.surfaceContainerHigh),
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: Icon(Icons.restaurant, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: colorScheme.tertiary),
                        const SizedBox(width: 2),
                        Text('${recipe.rating}', style: textTheme.labelSmall),
                        const SizedBox(width: 8),
                        Text('${recipe.ingredients.length} ingredients', style: textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              Text('${recipe.prepMinutes}m', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify and commit**

Run: `flutter analyze` — Expected: `No issues found!`

```bash
git add lib/widgets/featured_recipe_card.dart lib/widgets/quick_recipe_tile.dart
git commit -m "Add FeaturedRecipeCard and QuickRecipeTile widgets"
```

---

### Task 9: App bootstrap, router skeleton, and adaptive shell

**Files:**
- Create: `lib/router/app_router.dart`
- Modify: `lib/main.dart` (full replace)
- Create (stub, fleshed out in later tasks): `lib/screens/home_screen.dart`, `lib/screens/discover_screen.dart`, `lib/screens/favorites_screen.dart`, `lib/screens/profile_screen.dart`, `lib/screens/recipe_detail_screen.dart`, `lib/screens/add_recipe_screen.dart`

**Interfaces:**
- Consumes: `RecipeStore`, `RecipeStoreScope`, `ThemeController`, `ThemeControllerScope` (Task 4), `AppTheme` (Task 5), `RecipeRepository` (Task 3)
- Produces: `GoRouter buildRouter(RecipeStore store)`, `class AppShell extends StatelessWidget`, route names `home`, `discover`, `favorites`, `profile`, `recipe-detail`, `add-recipe`. Every screen in this task takes the exact constructor later tasks rely on: `RecipeDetailScreen({required String recipeId})`, all others take no required parameters.

This is a walking-skeleton task: every screen is a minimal `Scaffold` placeholder so the full navigation graph can be verified end-to-end before investing in real UI (Tasks 11-16 replace each stub's body).

- [ ] **Step 1: Create the 6 screen stubs**

`lib/screens/home_screen.dart`:
```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home')));
}
```

Repeat the same pattern for `lib/screens/discover_screen.dart` (`DiscoverScreen`, text `'Discover'`), `lib/screens/favorites_screen.dart` (`FavoritesScreen`, text `'Favorites'`), and `lib/screens/profile_screen.dart` (`ProfileScreen`, text `'Profile'`).

`lib/screens/recipe_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Recipe $recipeId')));
}
```

`lib/screens/add_recipe_screen.dart`:
```dart
import 'package:flutter/material.dart';

class AddRecipeScreen extends StatelessWidget {
  const AddRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add Recipe')));
}
```

- [ ] **Step 2: Implement `lib/router/app_router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/add_recipe_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../state/recipe_store.dart';

class _NavDestination {
  const _NavDestination(this.path, this.icon, this.selectedIcon, this.label);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = [
  _NavDestination('/', Icons.home_outlined, Icons.home, 'Home'),
  _NavDestination('/discover', Icons.search_outlined, Icons.search, 'Discover'),
  _NavDestination('/favorites', Icons.favorite_border, Icons.favorite, 'Favorites'),
  _NavDestination('/profile', Icons.person_outline, Icons.person, 'Profile'),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    final index = _destinations.indexWhere((d) => d.path == location);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    void onSelect(int index) => context.go(_destinations[index].path);

    if (isTablet) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onSelect,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in _destinations) NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
      ),
    );
  }
}

GoRouter buildRouter(RecipeStore store) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final match = RegExp(r'^/recipe/(.+)$').firstMatch(state.matchedLocation);
      if (match != null && store.byId(match.group(1)!) == null) {
        return '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', name: 'home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/discover', name: 'discover', builder: (context, state) => const DiscoverScreen()),
          GoRoute(path: '/favorites', name: 'favorites', builder: (context, state) => const FavoritesScreen()),
          GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/recipe/:id',
        name: 'recipe-detail',
        builder: (context, state) => RecipeDetailScreen(recipeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/add-recipe',
        name: 'add-recipe',
        builder: (context, state) => const AddRecipeScreen(),
      ),
    ],
  );
}
```

- [ ] **Step 3: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';

import 'data/recipe_repository.dart';
import 'router/app_router.dart';
import 'state/recipe_store.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = RecipeRepository();
  final recipes = await repository.loadRecipes();
  final categories = await repository.loadCategories();
  runApp(SavorlyApp(
    store: RecipeStore(initialRecipes: recipes, categories: categories),
    themeController: ThemeController(),
  ));
}

class SavorlyApp extends StatefulWidget {
  const SavorlyApp({super.key, required this.store, required this.themeController});

  final RecipeStore store;
  final ThemeController themeController;

  @override
  State<SavorlyApp> createState() => _SavorlyAppState();
}

class _SavorlyAppState extends State<SavorlyApp> {
  late final _router = buildRouter(widget.store);

  @override
  Widget build(BuildContext context) {
    return RecipeStoreScope(
      store: widget.store,
      child: ThemeControllerScope(
        controller: widget.themeController,
        child: AnimatedBuilder(
          animation: widget.themeController,
          builder: (context, _) => MaterialApp.router(
            title: 'Savorly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: widget.themeController.mode,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Delete the stale default widget test**

The default `test/widget_test.dart` from `flutter create` references a counter app that no longer exists.

```bash
rm test/widget_test.dart
```

- [ ] **Step 5: Verify the full app runs and navigates**

Run: `flutter analyze` — Expected: `No issues found!`
Run: `flutter run -d chrome` (or `-d windows`) and manually verify: the app opens on Home, tapping each of the 4 bottom nav items switches screens and updates the highlighted icon, and resizing the window past 600px width switches the bottom bar to a `NavigationRail`.

- [ ] **Step 6: Commit**

```bash
git add lib
git rm test/widget_test.dart
git commit -m "Wire up GoRouter shell with adaptive nav and screen stubs"
```

---

### Task 10: HomeScreen

**Files:**
- Modify: `lib/screens/home_screen.dart` (full replace)

**Interfaces:**
- Consumes: `RecipeStoreScope.of(context)` (Task 4), `FeaturedRecipeCard`, `QuickRecipeTile` (Task 8), `CategoryChip`, `SectionHeader` (Task 6)

Visual reference: `stitch_savorly_flutter_recipe_app/home_savorly/screen.png` and `code.html`.

- [ ] **Step 1: Implement `lib/screens/home_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/recipe_store.dart';
import '../widgets/category_chip.dart';
import '../widgets/featured_recipe_card.dart';
import '../widgets/quick_recipe_tile.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final featured = store.featured;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Good morning 👋', style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'What would you like to cook today?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                readOnly: true,
                onTap: () => context.go('/discover'),
                decoration: const InputDecoration(
                  hintText: 'Search recipes, ingredients...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: 'All',
                      selected: _selectedCategory == 'all',
                      onTap: () => setState(() => _selectedCategory = 'all'),
                    ),
                  ),
                  for (final category in store.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: category.name,
                        emoji: category.emoji,
                        selected: _selectedCategory == category.id,
                        onTap: () => setState(() => _selectedCategory = category.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (featured != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(icon: Icons.auto_awesome, title: 'Featured Recipe', subtitle: "Chef's Choice"),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FeaturedRecipeCard(recipe: featured, onTap: () => context.go('/recipe/${featured.id}')),
              ),
              const SizedBox(height: 24),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(icon: Icons.local_fire_department, title: 'Popular Recipes'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final recipe in store.popular)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 200,
                        child: QuickRecipeTile(recipe: recipe, onTap: () => context.go('/recipe/${recipe.id}')),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(icon: Icons.bolt, title: 'Quick & Easy', subtitle: 'Ready in under 30 minutes'),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final recipe in store.quickAndEasy)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: QuickRecipeTile(recipe: recipe, onTap: () => context.go('/recipe/${recipe.id}')),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
```

Note: the category chips filter state (`_selectedCategory`) is wired up but Home doesn't yet act on it beyond visual selection — matches the Stitch design, where Home's chips are a shortcut into filtered browsing while Discover (Task 11) is the actual filtered list screen. This is intentional, not a bug: tapping a chip other than "All" could optionally jump to `/discover`, which Task 11 will wire once Discover accepts an initial category — left as-is here to keep this task's scope to Home's own layout.

- [ ] **Step 2: Verify**

Run: `flutter analyze` — Expected: `No issues found!`
Run: `flutter run -d chrome` — Expected: Home shows greeting, search field, category chips, featured card, popular carousel, and quick & easy list, matching `home_savorly/screen.png`.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home_screen.dart
git commit -m "Implement HomeScreen matching the Stitch design"
```

---

### Task 11: DiscoverScreen

**Files:**
- Modify: `lib/screens/discover_screen.dart` (full replace)

**Interfaces:**
- Consumes: `RecipeStoreScope.of(context)`, `RecipeCard` (Task 7), `CategoryChip`, `SectionHeader` (Task 6)

This is the rubric's required "list screen with search/filtering". Visual reference: `stitch_savorly_flutter_recipe_app/discover_recipes_savorly/`.

- [ ] **Step 1: Implement `lib/screens/discover_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/recipe.dart';
import '../state/recipe_store.dart';
import '../widgets/category_chip.dart';
import '../widgets/recipe_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

enum _SortBy { popular, fastest }

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  _SortBy _sortBy = _SortBy.popular;
  int _maxPrepMinutes = 60;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _applyFilters(RecipeStore store) {
    var results = List<Recipe>.of(
      _searchController.text.isEmpty ? store.all : store.search(_searchController.text),
    );
    if (_selectedCategory != 'all') {
      results = results.where((r) => r.category == _selectedCategory).toList();
    }
    results = results.where((r) => r.prepMinutes <= _maxPrepMinutes).toList();
    if (_sortBy == _SortBy.popular) {
      results.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      results.sort((a, b) => a.prepMinutes.compareTo(b.prepMinutes));
    }
    return results;
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter & Sort', style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text('Max cooking time: $_maxPrepMinutes min'),
                  Slider(
                    value: _maxPrepMinutes.toDouble(),
                    min: 10,
                    max: 60,
                    divisions: 5,
                    label: '$_maxPrepMinutes min',
                    onChanged: (value) {
                      setSheetState(() => _maxPrepMinutes = value.round());
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<_SortBy>(
                    segments: const [
                      ButtonSegment(value: _SortBy.popular, label: Text('Popular'), icon: Icon(Icons.trending_up)),
                      ButtonSegment(value: _SortBy.fastest, label: Text('Fastest'), icon: Icon(Icons.bolt)),
                    ],
                    selected: {_sortBy},
                    onSelectionChanged: (selection) {
                      setSheetState(() => _sortBy = selection.first);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('Apply')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final results = _applyFilters(store);
        final width = MediaQuery.sizeOf(context).width;
        final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/add-recipe'),
            icon: const Icon(Icons.add),
            label: const Text('New Recipe'),
          ),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Discover Recipes', style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        'Explore ${store.all.length} curated culinary ideas',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Search recipes, ingredients...',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () => _openFilterSheet(context),
                            icon: const Icon(Icons.tune),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CategoryChip(
                                label: 'All',
                                selected: _selectedCategory == 'all',
                                onTap: () => setState(() => _selectedCategory = 'all'),
                              ),
                            ),
                            for (final category in store.categories)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CategoryChip(
                                  label: category.name,
                                  emoji: category.emoji,
                                  selected: _selectedCategory == category.id,
                                  onTap: () => setState(() => _selectedCategory = category.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: results.isEmpty
                    ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No recipes match your filters.'))))
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final recipe = results[index];
                            return RecipeCard(
                              recipe: recipe,
                              isFavorite: store.isFavorite(recipe.id),
                              onTap: () => context.push('/recipe/${recipe.id}'),
                              onFavoriteToggle: () => store.toggleFavorite(recipe.id),
                            );
                          },
                          childCount: results.length,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze` — Expected: `No issues found!`
Run: `flutter run -d chrome`, navigate to Discover, and manually verify: typing in the search field filters the grid, tapping a category chip filters by category, the filter sheet's slider narrows results by cook time, and the FAB navigates to `/add-recipe`.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/discover_screen.dart
git commit -m "Implement DiscoverScreen with search, category filter, sort, and filter sheet"
```

---

### Task 12: FavoritesScreen and ProfileScreen

**Files:**
- Modify: `lib/screens/favorites_screen.dart` (full replace)
- Modify: `lib/screens/profile_screen.dart` (full replace)

**Interfaces:**
- Consumes: `RecipeStoreScope.of(context)`, `ThemeControllerScope.of(context)`, `RecipeCard`

- [ ] **Step 1: Implement `lib/screens/favorites_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/recipe_store.dart';
import '../widgets/recipe_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final favorites = store.favorites;
        if (favorites.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No favorites yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap the heart on any recipe to save it here.', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        final width = MediaQuery.sizeOf(context).width;
        final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final recipe = favorites[index];
            return RecipeCard(
              recipe: recipe,
              isFavorite: true,
              onTap: () => context.push('/recipe/${recipe.id}'),
              onFavoriteToggle: () => store.toggleFavorite(recipe.id),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Implement `lib/screens/profile_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../state/recipe_store.dart';
import '../state/theme_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    final themeController = ThemeControllerScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([store, themeController]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 12),
            Center(child: Text('Yannick', style: Theme.of(context).textTheme.headlineSmall)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatTile(label: 'Recipes Added', value: '${store.all.length}'),
                _StatTile(label: 'Favorites', value: '${store.favorites.length}'),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark theme'),
                value: themeController.mode == ThemeMode.dark,
                onChanged: (_) => themeController.toggle(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze` — Expected: `No issues found!`
Run: `flutter run -d chrome`, verify: Favorites shows an empty state until you favorite a recipe from Discover, then shows it in a grid; Profile shows live stats and the dark-mode switch actually flips the whole app's theme.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/favorites_screen.dart lib/screens/profile_screen.dart
git commit -m "Implement FavoritesScreen and ProfileScreen with live theme toggle"
```

---

### Task 13: RecipeDetailScreen

**Files:**
- Modify: `lib/screens/recipe_detail_screen.dart` (full replace)

**Interfaces:**
- Consumes: `RecipeStoreScope.of(context)`, `Recipe`, `RecipeIngredient`, `RecipeStep`

Visual reference: `stitch_savorly_flutter_recipe_app/recipe_details_savorly/`. Uses a `DefaultTabController` for the Overview/Ingredients/Steps tabs.

- [ ] **Step 1: Implement `lib/screens/recipe_detail_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../state/recipe_store.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _servings = 2;
  final Set<int> _checkedIngredients = {};
  bool _initializedServings = false;

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature is coming soon!')));
  }

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final recipe = store.byId(widget.recipeId);
        if (recipe == null) {
          return const Scaffold(body: Center(child: Text('Recipe not found')));
        }
        if (!_initializedServings) {
          _servings = recipe.servings;
          _initializedServings = true;
        }
        final multiplier = recipe.servings == 0 ? 1.0 : _servings / recipe.servings;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(recipe.title, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  icon: Icon(store.isFavorite(recipe.id) ? Icons.favorite : Icons.favorite_border),
                  onPressed: () => store.toggleFavorite(recipe.id),
                ),
              ],
              bottom: const TabBar(tabs: [Tab(text: 'Overview'), Tab(text: 'Ingredients'), Tab(text: 'Steps')]),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: const Center(child: Icon(Icons.restaurant, size: 48)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OverviewTab(recipe: recipe),
                        _IngredientsTab(
                          recipe: recipe,
                          servings: _servings,
                          multiplier: multiplier,
                          checkedIngredients: _checkedIngredients,
                          onServingsChanged: (value) => setState(() => _servings = value),
                          onIngredientToggled: (index) => setState(() {
                            if (!_checkedIngredients.remove(index)) _checkedIngredients.add(index);
                          }),
                        ),
                        _StepsTab(recipe: recipe),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _showComingSoonSnackBar('Audio guide'),
                      icon: const Icon(Icons.headphones),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showComingSoonSnackBar('Cooking Mode'),
                        icon: const Icon(Icons.play_circle),
                        label: const Text('Start Cooking Mode'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(avatar: const Icon(Icons.schedule, size: 16), label: Text('${recipe.prepMinutes} min')),
              Chip(avatar: const Icon(Icons.local_fire_department, size: 16), label: Text('${recipe.calories} kcal')),
              Chip(avatar: const Icon(Icons.bar_chart, size: 16), label: Text(recipe.difficulty)),
              Chip(avatar: const Icon(Icons.star, size: 16), label: Text('${recipe.rating} (${recipe.ratingCount})')),
            ],
          ),
          const SizedBox(height: 16),
          Text(recipe.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(recipe.authorName),
              subtitle: const Text('Recipe author'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb),
                  SizedBox(width: 12),
                  Expanded(child: Text("Chef's Secret: read all steps once before starting to cook.")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  const _IngredientsTab({
    required this.recipe,
    required this.servings,
    required this.multiplier,
    required this.checkedIngredients,
    required this.onServingsChanged,
    required this.onIngredientToggled,
  });

  final Recipe recipe;
  final int servings;
  final double multiplier;
  final Set<int> checkedIngredients;
  final ValueChanged<int> onServingsChanged;
  final ValueChanged<int> onIngredientToggled;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$servings servings', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      IconButton(
                        onPressed: servings > 1 ? () => onServingsChanged(servings - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$servings'),
                      IconButton(
                        onPressed: () => onServingsChanged(servings + 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < recipe.ingredients.length; i++)
            CheckboxListTile(
              value: checkedIngredients.contains(i),
              onChanged: (_) => onIngredientToggled(i),
              title: Text(
                recipe.ingredients[i].name,
                style: checkedIngredients.contains(i) ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
              ),
              secondary: Text('${(recipe.ingredients[i].quantity * multiplier).toStringAsFixed(1)} ${recipe.ingredients[i].unit}'),
            ),
        ],
      ),
    );
  }
}

class _StepsTab extends StatelessWidget {
  const _StepsTab({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recipe.steps.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final step = recipe.steps[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primary,
                  child: Text('${index + 1}', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(step.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text('${step.minutes} min', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(step.description),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze` — Expected: `No issues found!`
Run: `flutter run -d chrome`, tap a recipe card, and verify: the hero image loads, all 3 tabs render real content, the servings stepper scales ingredient quantities live, checking an ingredient strikes it through, and both bottom-bar buttons show a `SnackBar`.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/recipe_detail_screen.dart
git commit -m "Implement RecipeDetailScreen with tabs, servings scaling, and ingredient checklist"
```

---

### Task 14: AddRecipeScreen

**Files:**
- Modify: `lib/screens/add_recipe_screen.dart` (full replace)

**Interfaces:**
- Consumes: `RecipeStoreScope.of(context)`, `Recipe`, `RecipeIngredient`, `RecipeStep` (Task 2), `image_picker`'s `ImagePicker`/`XFile`

This is the rubric's required "form with validation" screen. Cross-platform image preview and `SingleChildScrollView` are load-bearing per the spec's "Mobile & platform robustness" section.

- [ ] **Step 1: Implement `lib/screens/add_recipe_screen.dart`**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recipe.dart';
import '../state/recipe_store.dart';

class _IngredientDraft {
  _IngredientDraft() : name = TextEditingController(), quantity = TextEditingController(), unit = TextEditingController();
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
  }
}

class _StepDraft {
  _StepDraft() : title = TextEditingController(), description = TextEditingController();
  final TextEditingController title;
  final TextEditingController description;

  void dispose() {
    title.dispose();
    description.dispose();
  }
}

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepMinutesController = TextEditingController(text: '20');
  final _cookMinutesController = TextEditingController(text: '10');
  String _category = 'Dinner';
  int _servings = 2;
  String _difficulty = 'Medium';
  final List<_IngredientDraft> _ingredients = [_IngredientDraft()];
  final List<_StepDraft> _steps = [_StepDraft()];

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  static const _categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Healthy', 'Vegan', 'Drinks'];
  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepMinutesController.dispose();
    _cookMinutesController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
      });
    } else {
      setState(() => _pickedImage = picked);
    }
  }

  void _addIngredientRow() => setState(() => _ingredients.add(_IngredientDraft()));

  void _removeIngredientRow(int index) => setState(() {
        _ingredients[index].dispose();
        _ingredients.removeAt(index);
      });

  void _addStepRow() => setState(() => _steps.add(_StepDraft()));

  void _removeStepRow(int index) => setState(() {
        _steps[index].dispose();
        _steps.removeAt(index);
      });

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.every((i) => i.name.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one ingredient.')));
      return;
    }
    if (_steps.every((s) => s.description.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one step.')));
      return;
    }

    final recipe = Recipe(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80&auto=format&fit=crop',
      prepMinutes: int.parse(_prepMinutesController.text),
      cookMinutes: int.tryParse(_cookMinutesController.text) ?? 0,
      servings: _servings,
      difficulty: _difficulty,
      calories: 0,
      rating: 0,
      ratingCount: 0,
      authorName: 'You',
      ingredients: [
        for (final i in _ingredients)
          if (i.name.text.trim().isNotEmpty)
            RecipeIngredient(
              name: i.name.text.trim(),
              quantity: double.tryParse(i.quantity.text) ?? 1,
              unit: i.unit.text.trim().isEmpty ? 'unit' : i.unit.text.trim(),
            ),
      ],
      steps: [
        for (var s = 0; s < _steps.length; s++)
          if (_steps[s].description.text.trim().isNotEmpty)
            RecipeStep(
              title: _steps[s].title.text.trim().isEmpty ? 'Step ${s + 1}' : _steps[s].title.text.trim(),
              description: _steps[s].description.text.trim(),
              minutes: 5,
            ),
      ],
    );

    RecipeStoreScope.of(context).addRecipe(recipe);
    Navigator.of(context).pop();
  }

  Widget _buildImagePreview() {
    if (_pickedImage == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.photo_camera, size: 32), SizedBox(height: 8), Text('Tap to add a cover photo')],
        ),
      );
    }
    if (kIsWeb) {
      return Image.memory(_pickedImageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover);
    }
    return Image.file(File(_pickedImage!.path), height: 180, width: double.infinity, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recipe')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(onTap: _pickImage, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _buildImagePreview())),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Recipe Name *'),
                  validator: (value) =>
                      (value == null || value.trim().length < 3) ? 'Title must be at least 3 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prepMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Prep Time (min) *'),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          return (parsed == null || parsed <= 0) ? 'Enter a positive number' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cookMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cook Time (min)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category *'),
                        items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
                        onChanged: (value) => setState(() => _category = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$_servings servings'),
                          IconButton(onPressed: () => setState(() => _servings++), icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: [for (final d in _difficulties) ButtonSegment(value: d, label: Text(d))],
                  selected: {_difficulty},
                  onSelectionChanged: (selection) => setState(() => _difficulty = selection.first),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(onPressed: _addIngredientRow, icon: const Icon(Icons.add), label: const Text('Add')),
                  ],
                ),
                for (var i = 0; i < _ingredients.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _ingredients[i].name,
                            decoration: const InputDecoration(hintText: 'Ingredient'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _ingredients[i].quantity,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'Qty'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _ingredients[i].unit,
                            decoration: const InputDecoration(hintText: 'Unit'),
                          ),
                        ),
                        IconButton(
                          onPressed: _ingredients.length > 1 ? () => _removeIngredientRow(i) : null,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Steps', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(onPressed: _addStepRow, icon: const Icon(Icons.add), label: const Text('Add')),
                  ],
                ),
                for (var s = 0; s < _steps.length; s++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Step ${s + 1}', style: Theme.of(context).textTheme.labelLarge),
                                IconButton(
                                  onPressed: _steps.length > 1 ? () => _removeStepRow(s) : null,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            TextFormField(
                              controller: _steps[s].description,
                              maxLines: 2,
                              decoration: const InputDecoration(hintText: 'Describe this cooking step...'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(onPressed: _publish, icon: const Icon(Icons.check_circle), label: const Text('Publish Recipe')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze` — Expected: `No issues found!`
Run: `flutter run -d chrome`, open Add Recipe from Discover's FAB, and verify: submitting with an empty title/description shows validation errors, filling required fields and at least one ingredient/step then tapping Publish returns to Discover with the new recipe now visible in the grid, and tapping the cover photo opens the browser's file picker and shows a preview once one is chosen. Also run on Windows (`flutter run -d windows`) to confirm the non-web `Image.file`-equivalent path doesn't crash (the photo preview on desktop uses the same `kIsWeb` branch as mobile).

- [ ] **Step 3: Commit**

```bash
git add lib/screens/add_recipe_screen.dart
git commit -m "Implement AddRecipeScreen with dynamic ingredient/step rows and cross-platform image picker"
```

---

### Task 15: README with requirements traceability

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write `README.md`**

```markdown
# Savorly

A multi-screen Flutter recipe app — browse, discover, favorite, and publish recipes — built for the NextFlutter "Multi-screen app with navigation" certification.

## Features

- Browse recipes by category with a featured pick and curated carousels (Home)
- Search, filter by category/cook time, sort, and switch grid density (Discover)
- Rich recipe detail: tabbed Overview/Ingredients/Steps, a live servings-scaling ingredient checklist, and a numbered steps timeline
- Favorite recipes for quick access
- Publish your own recipe through a validated form with dynamic ingredient/step lists and a cover photo picker
- Light/dark theme, switchable from Profile

## Getting started

```bash
flutter pub get
flutter run -d chrome   # or: -d windows, -d <android-device-id>
```

Recipe photos are loaded from `images.unsplash.com` — an internet connection is needed to see them (a graceful fallback icon shows otherwise).

## Architecture

```
lib/
├── main.dart          # app bootstrap: loads JSON, builds RecipeStore, runs MaterialApp.router
├── theme/              # light/dark ColorScheme + Manrope text theme
├── router/              # GoRouter routes + adaptive (mobile/tablet) navigation shell
├── models/             # Recipe, RecipeIngredient, RecipeStep, Category
├── data/                # RecipeRepository — loads assets/data/*.json
├── state/                # RecipeStore, ThemeController (ChangeNotifier + InheritedNotifier)
├── screens/              # one file per screen
└── widgets/               # RecipeCard, FeaturedRecipeCard, QuickRecipeTile, CategoryChip, SectionHeader
```

Recipe/category data lives in `assets/data/*.json`, never hardcoded in a widget.

## Requirements checklist (NextFlutter rubric)

| Requirement | Where |
|---|---|
| At least 4 distinct screens | 6 screens: `lib/screens/home_screen.dart`, `discover_screen.dart`, `favorites_screen.dart`, `profile_screen.dart`, `recipe_detail_screen.dart`, `add_recipe_screen.dart` |
| GoRouter / named routes | `lib/router/app_router.dart` — `ShellRoute` with 4 named tab routes + 2 pushed named routes (`recipe-detail`, `add-recipe`) |
| List screen with search/filtering | `lib/screens/discover_screen.dart` — search field, category chips, cook-time filter sheet, sort |
| Detail screen with parameter passing | `lib/screens/recipe_detail_screen.dart` — `/recipe/:id` path parameter |
| Form with validation (3+ fields) | `lib/screens/add_recipe_screen.dart` — title, description, prep time, category (+ dynamic ingredient/step lists) |
| Light/dark theme | `lib/theme/app_theme.dart` + toggle in `lib/screens/profile_screen.dart` |
| 8+ different widgets | `ListView`, `GridView`/`SliverGrid`, `Stack`, `Card`, `TextFormField`, `DropdownButtonFormField`, `Chip`/`CategoryChip`, `NavigationBar`, `NavigationRail`, `TabBar`/`TabBarView`, `CheckboxListTile`, `showModalBottomSheet`, `Image.network`, `SnackBar` |
| 3+ reusable widgets in `widgets/` | `lib/widgets/recipe_card.dart`, `featured_recipe_card.dart`, `quick_recipe_tile.dart`, `category_chip.dart`, `section_header.dart` (5) |
| Responsive (mobile + tablet) | `lib/router/app_router.dart`'s `AppShell` (bottom bar ↔ rail at 600px) + grid column counts in `discover_screen.dart`/`favorites_screen.dart` |
| No hardcoded data in widgets | `assets/data/recipes.json` + `assets/data/categories.json`, loaded by `lib/data/recipe_repository.dart` |

## Testing

```bash
flutter test
```

Covers `Recipe`/`Category` JSON parsing, `RecipeRepository` asset loading, `RecipeStore`'s derived lists and mutators, `ThemeController`, and `RecipeCard`'s favorite/tap behavior.

## Screenshots

_Add screenshots here after running the app (Home, Discover, Recipe Detail, Add Recipe, dark mode)._
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "Add README with architecture overview and requirements traceability table"
```

---

### Task 16: Final verification pass

**Files:** none (verification only)

- [ ] **Step 1: Full analyze and test run**

Run: `flutter analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: all tests PASS (models, data, state, widgets — from Tasks 2, 3, 4, 7).

- [ ] **Step 2: Build for each verified platform**

```bash
flutter build apk --debug
flutter build web
flutter build windows
```

Expected: all three complete with exit code 0 (matches the smoke test already run earlier this session for the Android toolchain).

- [ ] **Step 3: Manual end-to-end walkthrough**

Run `flutter run -d chrome` and walk through: Home → tap featured recipe → Detail tabs/servings/checklist → back → Discover → search + filter + sort → tap a card → Detail → favorite it → Favorites tab shows it → Profile → toggle dark mode (whole app re-themes) → Discover FAB → Add Recipe → submit invalid form (see validation errors) → submit valid form with photo, 1 ingredient, 1 step → land back on Discover with the new recipe visible.

Resize the browser window past 600px width and confirm the bottom nav becomes a `NavigationRail` and Discover's grid gains a column.

- [ ] **Step 4: Note what's left for the user**

This plan produces a complete, working, tested app in this local repo. Two things remain that only the user can do (per the spec's "Delivery" section): create the public GitHub repository and push, and add real screenshots to `README.md` (needs a running instance to capture).
