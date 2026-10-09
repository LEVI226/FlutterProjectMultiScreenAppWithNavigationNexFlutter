import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/recipe_store.dart';
import '../widgets/recipe_card.dart';
import '../widgets/section_header.dart';

import 'package:savorly/l10n/app_localizations.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = RecipeStoreScope.of(context);
    final recipes = store.favorites;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          icon: Icons.favorite_border,
          title: l10n.favoritesTitle,
          subtitle: l10n.favoritesSavedCount(recipes.length),
        ),
        const SizedBox(height: 16),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 72),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.favoritesEmptyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => context.goNamed('discover'),
                  child: Text(l10n.favoritesFindRecipes),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
                isFavorite: true,
                onTap: () => context.pushNamed(
                  'recipe-detail',
                  pathParameters: {'id': recipe.id},
                ),
                onFavoriteToggle: () => store.toggleFavorite(recipe.id),
              );
            },
          ),
      ],
    );
  }
}
