# Savorly — Multi-screen Flutter App (Design Spec)

**Date:** 2026-09-19 (revised same day after receiving the Stitch UI design)
**Author:** Yannick Ouedraogo (with Claude)
**Context:** NextFlutter certification project "Flutter Project — Multi-screen app with navigation" (course: Navigation and Routing, 7/7 completed). Requires score ≥ 70/100. Submission is a public GitHub repo with README, screenshots, and launch instructions.

## Revision note

This supersedes the first version of this spec (also written 2026-09-19). The user designed the UI in Google Stitch and exported it to `stitch_savorly_flutter_recipe_app/` (sibling of this project's `docs/` folder). That export is the ground truth for screens, layout, colors, and typography — this revision replaces the originally invented "Recipe Book" concept (generic categories screen, deepOrange placeholder theme) with the actual **Savorly** design.

Design source: `../../../stitch_savorly_flutter_recipe_app/` — `home_savorly/`, `discover_recipes_savorly/`, `recipe_details_savorly/`, `create_recipe_savorly/` (each with `code.html` + `screen.png`), and `warm_culinary_studio/DESIGN.md` (design tokens).

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

**Savorly**: browse recipes, discover/filter/sort, view rich recipe detail (ingredients checklist, steps, servings scaling), mark favorites, publish a new recipe via a detailed form.

## Package / naming

- Dart package name: `savorly`
- App display title: "Savorly"
- Project root: this directory (`flutter-project-multi-screen-app`), its own public GitHub repo, separate from the non-git `nexTflutter` parent workspace.

## Design tokens (from `warm_culinary_studio/DESIGN.md`)

The DESIGN.md file contains two color descriptions that disagree: a YAML front-matter token block, and a prose "Colors" section with different hex values. **The YAML front-matter is what the actual exported HTML/Tailwind config uses** (verified: `primary: #a93017` matches in both the YAML and every `code.html`'s embedded Tailwind config) — the prose section is a stale/inconsistent draft. This spec follows the YAML tokens as ground truth.

- **Font:** Manrope (via the `google_fonts` package), weights 400/600/700/800, matching the display/headline/title/body/label scale in DESIGN.md.
- **Light `ColorScheme`:** built directly from the YAML tokens — `primary #a93017`, `secondary #3d692e`, `tertiary #805200`, `surface #f9f9f7`, `error #ba1a1a`, plus their `on-*`/container variants, mapped 1:1 to Flutter's M3 `ColorScheme` fields.
- **Dark `ColorScheme`:** DESIGN.md's prose dark-mode section doesn't reconcile with the YAML tokens and no dark HTML variant was exported, so the dark scheme is generated with `ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark)` — Material 3's standard tonal derivation from the same brand seed color, keeping light/dark visually consistent without hand-guessing unverified hex values.
- **Shape:** cards 16–20px radius, buttons/inputs 12–14px radius, chips fully pill-shaped — matches DESIGN.md's `rounded` scale.
- **Spacing:** 4/8/12/16/24px scale (DESIGN.md's `space-xs` → `space-xl`).

## Recipe photos

The exported HTML hardcodes `lh3.googleusercontent.com` preview URLs from the Stitch generation session — these are ephemeral AI-preview links, not meant for redistribution in a shipped app. `source.unsplash.com` (the original candidate) is a redirect service Unsplash has been deprecating and can return unstable/broken results, which is a real risk for a graded submission. Instead, recipe photos use **fixed `images.unsplash.com/photo-<id>` CDN URLs** — permanent, non-redirecting links to specific photos, picked and reachability-checked during implementation — stored as the `imageUrl` field in `assets/data/recipes.json` and loaded via `Image.network`. This is a data field, not a widget-level hardcode.

As a safety net against any link going stale after submission, `RecipeCard`, `FeaturedRecipeCard`, `QuickRecipeTile`, and the detail screen's hero image all use `Image.network(..., errorBuilder: ...)` falling back to a single bundled `assets/images/placeholder.png` (a simple food-icon-on-brand-color placeholder) — so a broken photo never shows a raw error icon during review. Screenshots for the README should still be taken with the device online so the real photos show.

## Architecture — flat layered structure under `lib/`

```
savorly/
├── assets/
│   └── data/
│       ├── recipes.json
│       └── categories.json
├── lib/
│   ├── main.dart                     # app entry, providers, MaterialApp.router
│   ├── theme/
│   │   └── app_theme.dart            # light/dark ColorScheme, Manrope text theme, shapes
│   ├── router/
│   │   └── app_router.dart           # GoRouter: ShellRoute (4 tabs) + pushed detail/add routes
│   ├── models/
│   │   ├── recipe.dart               # Recipe, RecipeIngredient, RecipeStep
│   │   └── category.dart             # Category (id, name, emoji)
│   ├── data/
│   │   └── recipe_repository.dart    # loads assets/data/*.json via rootBundle
│   ├── state/
│   │   ├── recipe_store.dart         # ChangeNotifier: recipes + favorites (in-memory, mutable)
│   │   └── theme_controller.dart     # ChangeNotifier: ThemeMode, toggle
│   ├── screens/
│   │   ├── home_screen.dart          # Stitch: home_savorly
│   │   ├── discover_screen.dart      # Stitch: discover_recipes_savorly — search/filter/sort
│   │   ├── favorites_screen.dart     # own design, reuses RecipeCard
│   │   ├── profile_screen.dart       # own design — stats + theme toggle
│   │   ├── recipe_detail_screen.dart # Stitch: recipe_details_savorly — :id param
│   │   └── add_recipe_screen.dart    # Stitch: create_recipe_savorly (header bug fixed)
│   └── widgets/
│       ├── recipe_card.dart          # grid/vertical card — Discover grid, Favorites list
│       ├── featured_recipe_card.dart # Home's large hero card
│       ├── quick_recipe_tile.dart    # Home's horizontal "Quick & Easy" row tile
│       ├── category_chip.dart        # selectable pill chip — Home + Discover
│       └── section_header.dart       # icon + title + trailing action, reused across sections
├── test/
├── analysis_options.yaml
└── README.md
```

## Navigation (GoRouter)

`ShellRoute` wraps an adaptive nav (mobile: `NavigationBar` bottom bar; tablet ≥600px: `NavigationRail`) with 4 destinations, matching every exported screen's bottom nav exactly:

- `/` → `HomeScreen`
- `/discover` → `DiscoverScreen` — the required list+search+filter screen
- `/favorites` → `FavoritesScreen`
- `/profile` → `ProfileScreen`

Outside the shell (pushed full-screen, no bottom nav):
- `/recipe/:id` → `RecipeDetailScreen` — path parameter, reachable from any recipe card on Home/Discover/Favorites; `redirect` guard sends unknown ids back to `/`
- `/add-recipe` → `AddRecipeScreen` — reached via a FAB on `DiscoverScreen` (the design has no dedicated bottom-nav slot for it; it's a modal-style full-screen push, consistent with typical "create" flows)

Deep linking demonstrated via Flutter web (typing `/recipe/<id>` into the browser address bar). No native platform deep-link config (intent filters / universal links) — out of scope per the earlier spec's reasoning.

### Note on the Stitch export

`create_recipe_savorly/code.html` has an export artifact: its header reads "Profile" and its `<nav>` highlights the Profile tab, even though the screen body is clearly the add/publish-recipe form (confirmed by the folder name and the "Publish Recipe" button). This is treated as a labeling bug in the Stitch generation, not a real design intent — the implementation uses an "Add Recipe" app bar title and no bottom nav (full-screen push), per the design fix agreed with the user.

## Data layer

- `assets/data/recipes.json`: array of recipe objects — `id, title, description, category, imageUrl, prepMinutes, cookMinutes, servings, difficulty (Easy/Medium/Hard), calories, rating, ratingCount, authorName, ingredients: [{name, quantity, unit}], steps: [{title, description, minutes}]`.
- `assets/data/categories.json`: array of `{id, name, emoji}` — powers the category chips on Home/Discover (matches the 🥞🥗🍲🍰🥑🌱🍹 emoji chips in the design) without hardcoding them in a widget.
- `RecipeRepository` loads both files via `rootBundle.loadString` + `jsonDecode` at startup; pure data access, no mutable state.

## State management

- `RecipeStore extends ChangeNotifier` — seeded from `RecipeRepository` at startup; single source of truth for recipe data during the session:
  - `List<Recipe> all` (base recipes + any added via the form)
  - `Set<String> favoriteIds`
  - Derived getters: `featured` (highest-rated recipe), `popular` (top-rated, for Home's carousel), `quickAndEasy` (`prepMinutes <= 30`, for Home's list), `search(query)`, `byCategory(categoryId)`
  - Mutators: `toggleFavorite(id)`, `addRecipe(recipe)`
  - Exposed app-wide via an `InheritedNotifier` with a static `of(context)` accessor — no external state package.
- `ThemeController extends ChangeNotifier` — `ThemeMode`, `toggle()`; surfaced as a switch on `ProfileScreen`.
- Ephemeral, screen-local state stays local (no global store): Discover's search text and active filter chip, Recipe Detail's servings stepper + ingredient-checked-off state, Add Recipe's in-progress dynamic ingredient/step rows and picked cover image.

## Screens

1. **Home** (`/`) — greeting header, search bar with a filter shortcut button, horizontal scrollable category chips, a `FeaturedRecipeCard` (top-rated recipe), a horizontal `Popular Recipes` carousel of `RecipeCard`s, a vertical `Quick & Easy` list of `QuickRecipeTile`s (recipes ≤30 min).
2. **Discover** (`/discover`) — the required list+search+filter screen: search field, filter-sheet trigger (`showModalBottomSheet` with a cook-time range and sort options), horizontal category filter chips, a sort indicator, a grid/list view toggle, and a 2-column (mobile) / 3–4-column (tablet) `GridView` of `RecipeCard`s.
3. **Favorites** (`/favorites`) — own design: same `RecipeCard`/list styling, filtered to `RecipeStore.favoriteIds`; empty state when none.
4. **Profile** (`/profile`) — own design: avatar placeholder, session stats (recipes added, favorites count — both derived from `RecipeStore`, not hardcoded), and the light/dark theme switch.
5. **Recipe Detail** (`/recipe/:id`) — hero image with time/difficulty/calorie/rating badges, title + description, author attribution card with a (decorative, non-persisted) follow toggle, a 3-tab `TabBar` (Overview / Ingredients / Steps), a servings stepper that live-recalculates ingredient quantities (matches the design's `data-base` multiplier pattern), a checkable ingredient list, a numbered steps timeline, a "Chef's Secret" tip callout, and a sticky bottom bar with "Start Cooking Mode" + an audio-guide icon button — both show a `SnackBar` only (no real timer/audio implementation, out of scope).
6. **Add Recipe** (`/add-recipe`) — cover photo picker (via `image_picker`, returning an `XFile`; previewed in memory with no persistence — see "Mobile & platform robustness" below for the cross-platform preview detail), title + description fields, prep/cook time fields, category dropdown (from `RecipeRepository.getCategories()`), a servings stepper, a difficulty segmented control, a dynamically add/remove-able ingredients list (name + quantity + unit per row, at least 1 required), a dynamically add/remove-able steps list (at least 1 required), and Cancel/Publish actions. Publish calls `RecipeStore.addRecipe(...)` and pops back to Discover.

## Reusable widgets (5, in `widgets/`)

1. `RecipeCard` — vertical card (image, category badge, favorite toggle, rating, title, time, difficulty); used in Discover's grid and Favorites' list.
2. `FeaturedRecipeCard` — Home's large hero card with gradient-scrim title overlay and a "View Recipe" CTA.
3. `QuickRecipeTile` — Home's horizontal list tile (thumbnail + title + rating + ingredient count).
4. `CategoryChip` — selectable pill chip with optional emoji; used on Home (browse) and Discover (filter).
5. `SectionHeader` — icon + title (+ optional subtitle/trailing action); used across Home's sections and Discover/Favorites headers.

Built-in widget variety across the app (well past the 8-widget requirement): `ListView`, `GridView`, `Stack`, `Card`, `TextField`/`TextFormField`, `DropdownButtonFormField`, `FilterChip`/`ChoiceChip`, `NavigationBar`, `NavigationRail`, `TabBar`/`TabBarView`, `Checkbox`, `showModalBottomSheet`, `Image.network`/`Image.file`, `SnackBar`, `CircularProgressIndicator` (initial JSON load).

## Form — Add Recipe

Validated fields: Title (required, min length 3), Description (required), Category (required dropdown, populated from data), Prep time (required, numeric, > 0). Plus structurally-validated dynamic lists: at least 1 ingredient row (name + quantity + unit) and at least 1 step row — comfortably clears the "at least 3 fields" requirement while matching the richer Stitch design. Cover photo, cook time, servings, and difficulty have sensible defaults and aren't required.

## Responsive strategy

Single breakpoint at 600px logical width:
- `< 600`: `NavigationBar` bottom bar; Discover grid at 2 columns; Home sections stay single-column/horizontal-scroll as designed.
- `>= 600`: `NavigationRail` instead of bottom bar; Discover grid at 3–4 columns; Recipe Detail could optionally widen its content column (not required, simple centering with a max width is sufficient).

## Mobile & platform robustness

Since the available run targets on this machine are Android, Chrome, Edge, and Windows desktop (verified via `flutter devices`), and this is a graded submission, the implementation plan must treat these as acceptance criteria, not nice-to-haves:

- **Cross-platform image picking:** `image_picker` returns an `XFile`, not a `dart:io File` (which doesn't exist on web). The Add Recipe cover photo preview is `kIsWeb`-aware: on web it reads the picked file's bytes (`await xFile.readAsBytes()`) and renders via `Image.memory`; on mobile/desktop it renders via `Image.file(File(xFile.path))`.
- **Keyboard safety in forms:** `AddRecipeScreen` wraps its content in a `SingleChildScrollView` so the on-screen keyboard never overflows or hides the focused field (dynamic ingredient/step rows make the form long even before the keyboard opens).
- **Safe areas:** screens with custom headers/bottom bars (Home, Discover, Recipe Detail's sticky action bar) respect `SafeArea`/`MediaQuery` padding rather than assuming a fixed status/nav bar height, matching the `pt-safe`/`pb-safe` treatment already present in the Stitch export.
- **Full scroll on all screens:** every screen's content is scrollable end-to-end (no clipped content on smaller phones or in landscape), including Recipe Detail's tab content and Home's stacked sections.
- **Image loading/error states:** every `Image.network` shows a `loadingBuilder` (progress indicator) while fetching and the `errorBuilder` fallback described above — no flash of blank space or raw error icons.

## Testing

- `models/recipe_test.dart` — `Recipe.fromJson`/`toJson` round trip, including nested ingredients/steps.
- `data/recipe_repository_test.dart` — loading and parsing fixture JSON.
- `state/recipe_store_test.dart` — `toggleFavorite`, `addRecipe`, and the `featured`/`popular`/`quickAndEasy`/`search`/`byCategory` derived getters.
- `widgets/recipe_card_test.dart` — widget test: renders title/image/badge, favorite icon reflects store state.

Pragmatic coverage over the logic most likely to have bugs (derived list logic, favorite toggling, form validation) — not exhaustive, consistent with certification-project scope.

## Delivery

- `analysis_options.yaml` using `package:lints/recommended.yaml`.
- `README.md`: description, architecture overview, folder structure, how to run, a screenshots section (filled in by the user after running the app, since screenshots need network access for the Unsplash images), and a **requirements traceability table** mapping each NextFlutter rubric line item (screens, GoRouter/named routes, list+search/filter, detail+params, form+validation, theme, 8+ widgets, 3+ reusable widgets, responsive, data/UI separation) to the specific screen(s) and/or file(s) that satisfy it — so a reviewer can verify each point in seconds.
- Git: this directory is its own repository, separate from the non-git `nexTflutter` parent. Creating the GitHub remote and pushing is a separate, explicit step the user confirms before it happens.

## Explicitly out of scope (YAGNI)

- External state management packages — not yet covered by the user's course sequence.
- Real network/API calls for recipe data (only `Image.network` for photos, which is a basic widget, not an API integration) — next course, not this one.
- Disk persistence of favorites/added recipes/theme choice — not required by the rubric.
- Platform-level deep link configuration — not required, not verifiable by a typical reviewer.
- Real "Cooking Mode" timer/audio-guide functionality — `SnackBar` feedback only, per user's choice.
- Persisting the Add Recipe cover photo beyond the current session.
