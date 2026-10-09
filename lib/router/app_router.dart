import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/add_recipe_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../state/recipe_store.dart';

import 'package:savorly/l10n/app_localizations.dart';

class _NavDestination {
  const _NavDestination(
    this.path,
    this.routeName,
    this.icon,
    this.selectedIcon,
    this.labelOf,
  );
  final String path;
  final String routeName;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(BuildContext context) labelOf;
}

String _homeLabel(BuildContext context) =>
    AppLocalizations.of(context)!.navHome;
String _discoverLabel(BuildContext context) =>
    AppLocalizations.of(context)!.navDiscover;
String _favoritesLabel(BuildContext context) =>
    AppLocalizations.of(context)!.navFavorites;
String _profileLabel(BuildContext context) =>
    AppLocalizations.of(context)!.navProfile;

const _destinations = [
  _NavDestination('/', 'home', Icons.home_outlined, Icons.home, _homeLabel),
  _NavDestination(
    '/discover',
    'discover',
    Icons.search_outlined,
    Icons.search,
    _discoverLabel,
  ),
  _NavDestination(
    '/favorites',
    'favorites',
    Icons.favorite_border,
    Icons.favorite,
    _favoritesLabel,
  ),
  _NavDestination(
    '/profile',
    'profile',
    Icons.person_outline,
    Icons.person,
    _profileLabel,
  ),
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

    void onSelect(int index) => context.goNamed(_destinations[index].routeName);

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
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.labelOf(context)),
                    ),
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
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.labelOf(context),
            ),
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
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/discover',
            name: 'discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/recipe/:id',
        name: 'recipe-detail',
        builder: (context, state) =>
            RecipeDetailScreen(recipeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/add-recipe',
        name: 'add-recipe',
        builder: (context, state) => const AddRecipeScreen(),
      ),
    ],
  );
}
