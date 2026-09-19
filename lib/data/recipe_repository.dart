import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/category.dart';
import '../models/recipe.dart';

class RecipeRepository {
  Future<List<Recipe>> loadRecipes() async {
    final raw = await rootBundle.loadString('assets/data/recipes.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Category>> loadCategories() async {
    final raw = await rootBundle.loadString('assets/data/categories.json');
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
