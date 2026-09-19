import 'package:flutter/material.dart';

import 'data/recipe_repository.dart';
import 'router/app_router.dart';
import 'state/recipe_store.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = RecipeRepository();
  final recipes = await repository.loadRecipes();
  final categories = await repository.loadCategories();
  runApp(
    SavorlyApp(
      store: RecipeStore(initialRecipes: recipes, categories: categories),
      themeController: ThemeController(),
    ),
  );
}

class SavorlyApp extends StatefulWidget {
  const SavorlyApp({
    super.key,
    required this.store,
    required this.themeController,
  });

  final RecipeStore store;
  final ThemeController themeController;

  @override
  State<SavorlyApp> createState() => _SavorlyAppState();
}

class _SavorlyAppState extends State<SavorlyApp> {
  late final _router = buildRouter(widget.store);

  @override
  Widget build(BuildContext context) {
    return RecipeStoreScope(
      store: widget.store,
      child: ThemeControllerScope(
        controller: widget.themeController,
        child: AnimatedBuilder(
          animation: widget.themeController,
          builder: (context, _) => MaterialApp.router(
            title: 'Savorly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: widget.themeController.mode,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
