import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recipe.dart';
import '../state/recipe_store.dart';

class _IngredientDraft {
  _IngredientDraft()
    : name = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      unit = TextEditingController(text: 'unit');

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
  }
}

class _StepDraft {
  _StepDraft()
    : title = TextEditingController(),
      description = TextEditingController();

  final TextEditingController title;
  final TextEditingController description;

  void dispose() {
    title.dispose();
    description.dispose();
  }
}

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepMinutesController = TextEditingController(text: '20');
  final _cookMinutesController = TextEditingController(text: '10');
  final List<_IngredientDraft> _ingredients = [_IngredientDraft()];
  final List<_StepDraft> _steps = [_StepDraft()];
  Uint8List? _pickedImageBytes;
  String _category = 'Dinner';
  String _difficulty = 'Medium';
  int _servings = 2;

  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepMinutesController.dispose();
    _cookMinutesController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _pickedImageBytes = bytes);
  }

  void _addIngredient() => setState(() => _ingredients.add(_IngredientDraft()));

  void _removeIngredient(int index) => setState(() {
    _ingredients[index].dispose();
    _ingredients.removeAt(index);
  });

  void _addStep() => setState(() => _steps.add(_StepDraft()));

  void _removeStep(int index) => setState(() {
    _steps[index].dispose();
    _steps.removeAt(index);
  });

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    final ingredients = _ingredients
        .where((draft) => draft.name.text.trim().isNotEmpty)
        .toList();
    final steps = _steps
        .where((draft) => draft.description.text.trim().isNotEmpty)
        .toList();
    if (ingredients.isEmpty || steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one ingredient and one step.'),
        ),
      );
      return;
    }

    final recipe = Recipe(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80&auto=format&fit=crop',
      prepMinutes: int.parse(_prepMinutesController.text),
      cookMinutes: int.tryParse(_cookMinutesController.text) ?? 0,
      servings: _servings,
      difficulty: _difficulty,
      calories: 0,
      rating: 0,
      ratingCount: 0,
      authorName: 'You',
      ingredients: [
        for (final draft in ingredients)
          RecipeIngredient(
            name: draft.name.text.trim(),
            quantity: double.tryParse(draft.quantity.text) ?? 1,
            unit: draft.unit.text.trim().isEmpty
                ? 'unit'
                : draft.unit.text.trim(),
          ),
      ],
      steps: [
        for (var index = 0; index < steps.length; index++)
          RecipeStep(
            title: steps[index].title.text.trim().isEmpty
                ? 'Step ${index + 1}'
                : steps[index].title.text.trim(),
            description: steps[index].description.text.trim(),
            minutes: 5,
          ),
      ],
    );

    RecipeStoreScope.of(context).addRecipe(recipe);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = RecipeStoreScope.of(context).categories;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recipe')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: _pickedImageBytes == null
                          ? ColoredBox(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_camera, size: 32),
                                  SizedBox(height: 8),
                                  Text('Tap to add a cover photo'),
                                ],
                              ),
                            )
                          : Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Recipe Name *'),
                  validator: (value) =>
                      (value == null || value.trim().length < 3)
                      ? 'Title must be at least 3 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prepMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prep Time *',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          return parsed == null || parsed <= 0
                              ? 'Enter a positive number'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cookMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cook Time',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text('${category.emoji} ${category.name}'),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Servings',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _servings > 1
                          ? () => setState(() => _servings--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_servings'),
                    IconButton(
                      onPressed: () => setState(() => _servings++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                SegmentedButton<String>(
                  selected: {_difficulty},
                  segments: [
                    for (final difficulty in _difficulties)
                      ButtonSegment(value: difficulty, label: Text(difficulty)),
                  ],
                  onSelectionChanged: (selection) =>
                      setState(() => _difficulty = selection.first),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Ingredients', onAdd: _addIngredient),
                for (var i = 0; i < _ingredients.length; i++)
                  _IngredientRow(
                    draft: _ingredients[i],
                    canRemove: _ingredients.length > 1,
                    onRemove: () => _removeIngredient(i),
                  ),
                const SizedBox(height: 12),
                _SectionTitle(title: 'Steps', onAdd: _addStep),
                for (var i = 0; i < _steps.length; i++)
                  _StepRow(
                    index: i,
                    draft: _steps[i],
                    canRemove: _steps.length > 1,
                    onRemove: () => _removeStep(i),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _publish,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Publish Recipe'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final _IngredientDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: draft.name,
              decoration: const InputDecoration(hintText: 'Ingredient'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: draft.quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Qty'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: draft.unit,
              decoration: const InputDecoration(hintText: 'Unit'),
            ),
          ),
          IconButton(
            onPressed: canRemove ? onRemove : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _StepDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Step ${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: canRemove ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              controller: draft.title,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: draft.description,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Describe this cooking step',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
