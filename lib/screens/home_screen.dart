import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/recipe_store.dart';
import '../widgets/category_chip.dart';
import '../widgets/featured_recipe_card.dart';
import '../widgets/quick_recipe_tile.dart';
import '../widgets/recipe_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'Good morning',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'What would you like to cook?',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => context.go('/discover'),
              icon: const Icon(Icons.tune),
              tooltip: 'Discover recipes',
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          readOnly: true,
          onTap: () => context.go('/discover'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search recipes',
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
                onTap: () => context.go('/discover'),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          icon: Icons.local_fire_department_outlined,
          title: 'Featured Recipe',
        ),
        const SizedBox(height: 12),
        if (featured != null)
          FeaturedRecipeCard(
            recipe: featured,
            onTap: () => context.push('/recipe/${featured.id}'),
          ),
        const SizedBox(height: 24),
        SectionHeader(
          icon: Icons.star_border,
          title: 'Popular Recipes',
          trailing: TextButton(
            onPressed: () => context.go('/discover'),
            child: const Text('See all'),
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
                  onTap: () => context.push('/recipe/${recipe.id}'),
                  onFavoriteToggle: () => store.toggleFavorite(recipe.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          icon: Icons.bolt_outlined,
          title: 'Quick & Easy',
          subtitle: 'Ready in 30 minutes or less',
        ),
        const SizedBox(height: 12),
        for (final recipe in quick)
          QuickRecipeTile(
            recipe: recipe,
            onTap: () => context.push('/recipe/${recipe.id}'),
          ),
      ],
    );
  }
}
