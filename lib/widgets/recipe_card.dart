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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Card(
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
