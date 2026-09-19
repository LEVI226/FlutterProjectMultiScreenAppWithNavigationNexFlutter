import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/recipe.dart';
import '../state/recipe_store.dart';
import '../widgets/category_chip.dart';
import '../widgets/recipe_card.dart';
import '../widgets/section_header.dart';

enum _SortMode { rating, quickest, newest }

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _category = 'all';
  _SortMode _sortMode = _SortMode.rating;
  double _maxCookMinutes = 90;
  bool _denseGrid = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _recipes(RecipeStore store) {
    var recipes = List<Recipe>.of(
      _searchController.text.trim().isEmpty
          ? store.all
          : store.search(_searchController.text),
    );
    if (_category != 'all') {
      recipes = recipes
          .where((recipe) => recipe.category == _category)
          .toList();
    }
    recipes = recipes
        .where(
          (recipe) =>
              recipe.prepMinutes + recipe.cookMinutes <= _maxCookMinutes,
        )
        .toList();
    switch (_sortMode) {
      case _SortMode.rating:
        recipes.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortMode.quickest:
        recipes.sort(
          (a, b) => (a.prepMinutes + a.cookMinutes).compareTo(
            b.prepMinutes + b.cookMinutes,
          ),
        );
      case _SortMode.newest:
        recipes = recipes.reversed.toList();
    }
    return recipes;
  }

  Future<void> _showFilters() async {
    var pendingSort = _sortMode;
    var pendingMax = _maxCookMinutes;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Text('Max total time: ${pendingMax.round()} min'),
                Slider(
                  value: pendingMax,
                  min: 15,
                  max: 90,
                  divisions: 5,
                  label: '${pendingMax.round()} min',
                  onChanged: (value) => setSheetState(() => pendingMax = value),
                ),
                const SizedBox(height: 8),
                SegmentedButton<_SortMode>(
                  selected: {pendingSort},
                  segments: const [
                    ButtonSegment(
                      value: _SortMode.rating,
                      label: Text('Top'),
                      icon: Icon(Icons.star),
                    ),
                    ButtonSegment(
                      value: _SortMode.quickest,
                      label: Text('Fast'),
                      icon: Icon(Icons.bolt),
                    ),
                    ButtonSegment(
                      value: _SortMode.newest,
                      label: Text('New'),
                      icon: Icon(Icons.fiber_new),
                    ),
                  ],
                  onSelectionChanged: (selection) =>
                      setSheetState(() => pendingSort = selection.first),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _sortMode = pendingSort;
                      _maxCookMinutes = pendingMax;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = RecipeStoreScope.of(context);
    final recipes = _recipes(store);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900
        ? 4
        : width >= 600
        ? 3
        : _denseGrid
        ? 3
        : 2;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          SectionHeader(
            icon: Icons.search,
            title: 'Discover',
            subtitle: '${recipes.length} recipes found',
            trailing: IconButton.filledTonal(
              onPressed: _showFilters,
              icon: const Icon(Icons.tune),
              tooltip: 'Filters',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by recipe name',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: 'All',
                    selected: _category == 'all',
                    onTap: () => setState(() => _category = 'all'),
                  ),
                ),
                for (final category in store.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: category.name,
                      emoji: category.emoji,
                      selected: _category == category.id,
                      onTap: () => setState(() => _category = category.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text('Sort: ${_sortMode.name}')),
              IconButton(
                onPressed: () => setState(() => _denseGrid = !_denseGrid),
                icon: Icon(
                  _denseGrid ? Icons.grid_view : Icons.view_module_outlined,
                ),
                tooltip: 'Grid density',
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
                isFavorite: store.isFavorite(recipe.id),
                onTap: () => context.push('/recipe/${recipe.id}'),
                onFavoriteToggle: () => store.toggleFavorite(recipe.id),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-recipe'),
        icon: const Icon(Icons.add),
        label: const Text('Recipe'),
      ),
    );
  }
}
