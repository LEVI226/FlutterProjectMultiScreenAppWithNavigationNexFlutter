import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../state/recipe_store.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<int> _checkedIngredients = {};
  var _servings = 1;
  var _initializedServings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    final recipe = store.byId(widget.recipeId);
    if (recipe == null) {
      return const Scaffold(body: Center(child: Text('Recipe not found')));
    }
    if (!_initializedServings) {
      _servings = recipe.servings;
      _initializedServings = true;
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                onPressed: () =>
                    setState(() => store.toggleFavorite(recipe.id)),
                icon: Icon(
                  store.isFavorite(recipe.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                tooltip: 'Favorite',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : ColoredBox(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                          ),
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: const Icon(Icons.restaurant, size: 48),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _RecipeSummary(recipe: recipe),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Ingredients'),
                  Tab(text: 'Steps'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(recipe: recipe),
                    _IngredientsTab(
                      recipe: recipe,
                      servings: _servings,
                      checked: _checkedIngredients,
                      onServingChanged: (value) =>
                          setState(() => _servings = value),
                      onChecked: (index, checked) => setState(() {
                        if (checked) {
                          _checkedIngredients.add(index);
                        } else {
                          _checkedIngredients.remove(index);
                        }
                      }),
                    ),
                    _StepsTab(recipe: recipe),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _snack('Cooking mode is a future upgrade.'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Cooking'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _snack('Audio guide is a future upgrade.'),
                icon: const Icon(Icons.volume_up),
                tooltip: 'Audio guide',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeSummary extends StatelessWidget {
  const _RecipeSummary({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Badge(
            icon: Icons.schedule,
            text: '${recipe.prepMinutes + recipe.cookMinutes} min',
          ),
          _Badge(
            icon: Icons.local_fire_department_outlined,
            text: '${recipe.calories} cal',
          ),
          _Badge(icon: Icons.restaurant_menu, text: recipe.difficulty),
          _Badge(
            icon: Icons.star,
            text: '${recipe.rating} (${recipe.ratingCount})',
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(text));
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.recipe});

  final Recipe recipe;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(recipe.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(recipe.authorName),
            subtitle: const Text('Recipe creator'),
            trailing: FilledButton.tonal(
              onPressed: () => setState(() => _following = !_following),
              child: Text(_following ? 'Following' : 'Follow'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chef Secret: season in small layers and taste before serving.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _IngredientsTab extends StatelessWidget {
  const _IngredientsTab({
    required this.recipe,
    required this.servings,
    required this.checked,
    required this.onServingChanged,
    required this.onChecked,
  });

  final Recipe recipe;
  final int servings;
  final Set<int> checked;
  final ValueChanged<int> onServingChanged;
  final void Function(int index, bool checked) onChecked;

  @override
  Widget build(BuildContext context) {
    final multiplier = servings / recipe.servings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('Servings', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              onPressed: servings > 1
                  ? () => onServingChanged(servings - 1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$servings'),
            IconButton(
              onPressed: () => onServingChanged(servings + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < recipe.ingredients.length; i++)
          CheckboxListTile(
            value: checked.contains(i),
            onChanged: (value) => onChecked(i, value ?? false),
            title: Text(recipe.ingredients[i].name),
            subtitle: Text(
              '${(recipe.ingredients[i].quantity * multiplier).toStringAsFixed(1)} ${recipe.ingredients[i].unit}',
            ),
          ),
      ],
    );
  }
}

class _StepsTab extends StatelessWidget {
  const _StepsTab({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recipe.steps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final step = recipe.steps[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(step.title),
            subtitle: Text('${step.description}\n${step.minutes} min'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
