import 'package:flutter/material.dart';

import '../state/recipe_store.dart';
import '../state/theme_controller.dart';
import '../widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    final theme = ThemeControllerScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final userRecipes = store.all
        .where((recipe) => recipe.id.startsWith('user-'))
        .length;
    final isDark = theme.mode == ThemeMode.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          icon: Icons.person_outline,
          title: 'Profile',
          subtitle: 'Your Savorly kitchen',
        ),
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 44,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            size: 48,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Yannick Ouedraogo',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth < 420
                ? constraints.maxWidth
                : (constraints.maxWidth - 24) / 3;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _StatCard(
                    label: 'Recipes',
                    value: '${store.all.length}',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _StatCard(label: 'Added', value: '$userRecipes'),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _StatCard(
                    label: 'Favorites',
                    value: '${store.favoriteIds.length}',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: const Text('Switch the app theme'),
            value: isDark,
            onChanged: (_) => theme.toggle(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
