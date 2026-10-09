import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/recipe.dart';
import '../state/recipe_store.dart';
import '../widgets/category_chip.dart';
import '../widgets/recipe_card.dart';
import '../widgets/section_header.dart';

import 'package:savorly/l10n/app_localizations.dart';

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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.discoverFiltersTitle,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.discoverMaxTime(pendingMax.round())),
                  Slider(
                    value: pendingMax,
                    min: 15,
                    max: 90,
                    divisions: 5,
                    label: '${pendingMax.round()} min',
                    onChanged: (value) =>
                        setSheetState(() => pendingMax = value),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<_SortMode>(
                    selected: {pendingSort},
                    segments: [
                      ButtonSegment(
                        value: _SortMode.rating,
                        label: Text(l10n.discoverSortTop),
                        icon: const Icon(Icons.star),
                      ),
                      ButtonSegment(
                        value: _SortMode.quickest,
                        label: Text(l10n.discoverSortFast),
                        icon: const Icon(Icons.bolt),
                      ),
                      ButtonSegment(
                        value: _SortMode.newest,
                        label: Text(l10n.discoverSortNew),
                        icon: const Icon(Icons.fiber_new),
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
                    child: Text(l10n.discoverApplyFilters),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            title: l10n.discoverTitle,
            subtitle: l10n.discoverRecipesFound(recipes.length),
            trailing: IconButton.filledTonal(
              onPressed: _showFilters,
              icon: const Icon(Icons.tune),
              tooltip: l10n.discoverFiltersTooltip,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.discoverSearchHint,
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
                    label: l10n.discoverAllCategory,
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
                tooltip: l10n.discoverGridDensityTooltip,
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
                onTap: () => context.pushNamed(
                  'recipe-detail',
                  pathParameters: {'id': recipe.id},
                ),
                onFavoriteToggle: () => store.toggleFavorite(recipe.id),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('add-recipe'),
        icon: const Icon(Icons.add),
        label: Text(l10n.discoverAddRecipeFab),
      ),
    );
  }
}
