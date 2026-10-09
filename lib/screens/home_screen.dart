import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/recipe_store.dart';
import '../widgets/category_chip.dart';
import '../widgets/featured_recipe_card.dart';
import '../widgets/quick_recipe_tile.dart';
import '../widgets/recipe_card.dart';
import '../widgets/section_header.dart';
import 'package:savorly/l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = RecipeStoreScope.of(context);
    final featured = store.featured;
    final popular = store.popular;
    final quick = store.quickAndEasy.take(4).toList();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeGreeting,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l10n.homeQuestion,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => context.goNamed('discover'),
              icon: const Icon(Icons.tune),
              tooltip: l10n.homeDiscoverTooltip,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          readOnly: true,
          onTap: () => context.goNamed('discover'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.homeSearchHint,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: store.categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = store.categories[index];
              return CategoryChip(
                label: category.name,
                emoji: category.emoji,
                selected: false,
                onTap: () => context.goNamed('discover'),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          icon: Icons.local_fire_department_outlined,
          title: l10n.homeFeaturedRecipe,
        ),
        const SizedBox(height: 12),
        if (featured != null)
          FeaturedRecipeCard(
            recipe: featured,
            onTap: () => context.pushNamed(
              'recipe-detail',
              pathParameters: {'id': featured.id},
            ),
          ),
        const SizedBox(height: 24),
        SectionHeader(
          icon: Icons.star_border,
          title: l10n.homePopularRecipes,
          trailing: TextButton(
            onPressed: () => context.goNamed('discover'),
            child: Text(l10n.homeSeeAll),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 235,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popular.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final recipe = popular[index];
              return SizedBox(
                width: 190,
                child: RecipeCard(
                  recipe: recipe,
                  isFavorite: store.isFavorite(recipe.id),
                  onTap: () => context.pushNamed(
                    'recipe-detail',
                    pathParameters: {'id': recipe.id},
                  ),
                  onFavoriteToggle: () => store.toggleFavorite(recipe.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          icon: Icons.bolt_outlined,
          title: l10n.homeQuickAndEasy,
          subtitle: l10n.homeQuickSubtitle,
        ),
        const SizedBox(height: 12),
        for (final recipe in quick)
          QuickRecipeTile(
            recipe: recipe,
            onTap: () => context.pushNamed(
              'recipe-detail',
              pathParameters: {'id': recipe.id},
            ),
          ),
      ],
    );
  }
}
