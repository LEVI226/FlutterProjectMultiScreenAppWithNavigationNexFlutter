# Recipe Book — Multi-screen Flutter App (Design Spec)

**Date:** 2026-09-19
**Author:** Yannick Ouedraogo (with Claude)
**Context:** NextFlutter certification project "Flutter Project — Multi-screen app with navigation" (course: Navigation and Routing, 7/7 completed). Requires score ≥ 70/100. Submission is a public GitHub repo with README, screenshots, and launch instructions.

## Grading requirements (verbatim from course)

- Topic of the user's choice
- At least 4 distinct screens
- Navigation with GoRouter or Navigator 2.0 (named routes)
- A list screen with search/filtering
- A detail screen with parameter passing
- A form with validation (at least 3 fields)
- Light/dark theme support
- At least 8 different widgets (ListView, GridView, Stack, Card, etc.)
- At least 3 reusable custom widgets in a `widgets/` folder
- Responsive: adapt to mobile and tablet
- No hardcoded data in widgets (UI/data separation)

## Topic

Recipe Book: browse recipes, filter by category, view details, mark favorites, add a new recipe via a form.

## Package / naming

- Dart package name: `recipe_book`
- App display title: "Recipe Book"
- Project root: this directory (`flutter-project-multi-screen-app`), which becomes its own public GitHub repo, separate from the parent `nexTflutter` workspace (which is not a git repo).

## Architecture — flat layered structure under `lib/`

Chosen over a feature-first layout because the grading rubric explicitly names a `widgets/` folder; a shallow, rubric-aligned structure is easier for a reviewer to scan quickly. This mirrors the layering style of the user's existing certified CLI project (`cliTASkmanager`), adapted to Flutter's conventional `screens/`/`widgets/` split.

```
recipe_book/
├── assets/
│   └── data/
│       ├── recipes.json
│       └── categories.json
├── lib/
│   ├── main.dart                     # app entry, providers, MaterialApp.router
│   ├── theme/
│   │   └── app_theme.dart            # ThemeData.light()/dark(), Material 3 seed color
│   ├── router/
│   │   └── app_router.dart           # GoRouter config: routes, ShellRoute, redirect guard
│   ├── models/
│   │   ├── recipe.dart               # Recipe (id, title, category, imageUrl, prepMinutes,
│   │   │                             #   servings, difficulty, ingredients, steps)
│   │   └── category.dart             # Category (id, name, icon)
│   ├── data/
│   │   └── recipe_repository.dart    # loads assets/data/*.json via rootBundle,
│   │                                 #   exposes getAll/getById/search/byCategory/getCategories/add
│   ├── state/
│   │   ├── favorites_controller.dart # ChangeNotifier: Set<String> favoriteIds, toggle, isFavorite
│   │   └── theme_controller.dart     # ChangeNotifier: ThemeMode, toggle
│   ├── screens/
│   │   ├── home_screen.dart          # list + search + category quick-filter
│   │   ├── categories_screen.dart    # grid of categories
│   │   ├── category_recipes_screen.dart # nested route: recipes filtered by category
│   │   ├── recipe_detail_screen.dart # detail via :id param
│   │   ├── favorites_screen.dart     # list of favorited recipes
│   │   └── add_recipe_screen.dart    # form, 4 validated fields
│   └── widgets/
│       ├── recipe_card.dart          # reusable — used in Home, CategoryRecipes, Favorites
│       ├── category_card.dart        # reusable — used in Categories grid
│       ├── search_filter_bar.dart    # reusable — used in Home
│       └── adaptive_nav_scaffold.dart # reusable — shared shell, mobile/tablet nav switch
├── test/
│   ├── models/recipe_test.dart
│   ├── data/recipe_repository_test.dart
│   ├── state/favorites_controller_test.dart
│   └── widgets/recipe_card_test.dart
├── analysis_options.yaml
└── README.md
```

## Navigation (GoRouter)

State management for navigation-independent app state uses no external package (per user's choice, consistent with the course sequence — Riverpod is taught in a later, not-yet-completed course).

Route tree:

- `ShellRoute` — wraps the adaptive nav scaffold (BottomNavigationBar on mobile, NavigationRail on tablet), containing the three primary destinations:
  - `/` → `HomeScreen` (list, search box, category filter chips)
  - `/categories` → `CategoriesScreen` (grid of category cards)
    - `/categories/:categoryId` (nested child route) → `CategoryRecipesScreen` (list filtered by category) — demonstrates nested routes + path parameters from the course
  - `/favorites` → `FavoritesScreen`
- Outside the shell (pushed full-screen from anywhere):
  - `/recipe/:id` → `RecipeDetailScreen` — parameter passing via path param; includes a `redirect` guard: if `id` doesn't resolve to a known recipe, redirect to `/`
  - `/add-recipe` → `AddRecipeScreen`

Deep linking is demonstrated primarily via Flutter web (typing `/recipe/<id>` directly into the browser address bar and reloading); GoRouter's URL-based routing supports this without extra platform configuration. Android/iOS platform-level deep link config (intent filters / universal links) is out of scope — not required by the rubric and not verifiable by a typical reviewer.

## Data layer

- `assets/data/recipes.json`: array of recipe objects (id, title, category id, imageUrl, prepMinutes, servings, difficulty, ingredients: List<String>, steps: List<String>).
- `assets/data/categories.json`: array of category objects (id, name, icon name).
- `RecipeRepository` loads both files via `rootBundle.loadString` + `jsonDecode` at startup, and exposes synchronous in-memory query methods (`getAll`, `getById`, `search(query)`, `byCategory(categoryId)`, `getCategories`, `add(recipe)` for the form submission). No widget ever embeds recipe/category data directly — all screens read through the repository.

## State management

- `FavoritesController extends ChangeNotifier`: holds `Set<String> favoriteIds`, exposes `toggle(id)` and `isFavorite(id)`.
- `ThemeController extends ChangeNotifier`: holds `ThemeMode`, exposes `toggle()`.
- Both exposed app-wide via `InheritedNotifier` subclasses with a static `of(context)` accessor (the "poor-man's provider" pattern) — no external state management package.
- Favorites and recipes added via the form are in-memory only for the session; no disk persistence (out of scope for this rubric, avoids adding `shared_preferences` or similar as an unnecessary dependency).
- Search/filter query text lives as local `StatefulWidget` state inside `HomeScreen` (no need for global state).

## Theming

- Material 3, `ThemeData.light()` and `ThemeData.dark()` built from a single seed color (deepOrange, food-appropriate).
- `MaterialApp.router.themeMode` driven by `ThemeController`.
- Toggle exposed as a sun/moon `IconButton` in the shared shell's AppBar, reachable from Home/Categories/Favorites.

## Reusable widgets (4, in `widgets/`)

1. `RecipeCard` — `Card` + `Stack` (image + favorite-heart overlay) + text; used in Home, CategoryRecipes, Favorites.
2. `CategoryCard` — `Card`/`InkWell` + `Icon` + label; used in Categories grid.
3. `SearchFilterBar` — `TextField` + `Wrap` of `FilterChip`s; used in Home.
4. `AdaptiveNavScaffold` — switches `BottomNavigationBar` (mobile) vs `NavigationRail` (tablet) based on width breakpoint; used by the `ShellRoute` builder.

Built-in widget variety across the app (comfortably clears the "8 different widgets" requirement): `ListView`, `GridView`, `Stack`, `Card`, `TextField`, `FilterChip`, `NavigationRail`, `BottomNavigationBar`, `Form`/`TextFormField`, `DropdownButtonFormField`, `Image`, `AlertDialog`, `CircularProgressIndicator` (initial JSON load).

## Form — Add Recipe

Fields (4, all validated):
- Title — required, non-empty, min length 3
- Category — required dropdown (populated from `RecipeRepository.getCategories()`, not hardcoded)
- Prep time (minutes) — required, numeric, > 0
- Servings — required, numeric, > 0

On submit: builds a `Recipe`, calls `RecipeRepository.add(...)`, navigates back to `/` where the new recipe appears in the list — demonstrates a full read/write round trip without needing persistence.

## Responsive strategy

Single breakpoint at 600px logical width (checked via `MediaQuery`/`LayoutBuilder`):
- `< 600`: `ListView` layouts, `BottomNavigationBar`.
- `>= 600`: `GridView` layouts (2–3 columns) for Home/Categories/Favorites, `NavigationRail` instead of bottom nav.

## Testing

Mirrors the testing habit from the user's certified CLI project:
- `models/recipe_test.dart` — `Recipe.fromJson`/`toJson` round trip.
- `data/recipe_repository_test.dart` — search and category-filter logic against fixture JSON.
- `state/favorites_controller_test.dart` — toggle/isFavorite behavior and notifyListeners.
- `widgets/recipe_card_test.dart` — widget test: renders title/image, favorite icon reflects state.

Not aiming for exhaustive coverage — pragmatic tests over the logic most likely to have bugs (parsing, filtering, favorite toggling), consistent with the scope of a certification project.

## Delivery

- `analysis_options.yaml` using `package:lints/recommended.yaml` (same convention as `cliTASkmanager`).
- `README.md`: description, feature checklist mapped to the rubric, architecture overview, folder structure, how to run (`flutter pub get && flutter run`), and a placeholder section for screenshots (to be filled in by the user after running the app, since screenshots require an actual running instance).
- Git: this directory is initialized as its own repository (separate from the non-git `nexTflutter` parent workspace) so it can be pushed to a dedicated public GitHub repo for submission. Creating the GitHub remote and pushing is a separate, explicit step the user confirms before it happens — not assumed as part of this design.

## Explicitly out of scope (YAGNI)

- External state management packages (Provider/Riverpod/Bloc) — not yet covered by the user's course sequence.
- Remote API / network calls — next course, not this one.
- Disk persistence of favorites/added recipes — not required by the rubric.
- Platform-level deep link configuration (Android intent filters, iOS universal links) — not verifiable by a typical reviewer and not required by the rubric; web-based deep linking is sufficient to demonstrate the concept.
