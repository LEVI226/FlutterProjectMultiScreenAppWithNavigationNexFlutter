# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.2.0] - 2026-10-10

### Added

- CI/CD via GitHub Actions: automatic `dart format` check, `flutter analyze`, and `flutter test` on every push and pull request.
- This changelog.

## [1.1.0] - 2026-10-10

### Added

- Internationalization: French and English support via `flutter_localizations`/`intl`, with a language switcher on the Profile screen (defaults to the device's locale, overridable per session).
- Accessibility: semantic labels on every previously icon-only interactive control (favorite toggle, ingredient/step removal, servings steppers).
- Performance: recipe images now load through `cached_network_image` (disk+memory caching, fade-in transition) instead of uncached `Image.network`; audited and added missing `const` constructors across widgets and screens.
- Widget tests for `DiscoverScreen` (search, category filter, grid density) and `AddRecipeScreen` (form validation, successful publish).
- Integration tests covering the favorite-a-recipe flow and the publish-a-new-recipe flow, using the `integration_test` package.

## [1.0.0] - 2026-09-20

### Added

- Initial release: 6-screen recipe app (Home, Discover, Favorites, Profile, Recipe Detail, Add Recipe) with GoRouter navigation, an adaptive `NavigationBar`/`NavigationRail` shell, light/dark theming, and bundled-JSON recipe data via `RecipeRepository`.
- Certified 99/100 for the NextFlutter "Multi-screen app with navigation" project.
