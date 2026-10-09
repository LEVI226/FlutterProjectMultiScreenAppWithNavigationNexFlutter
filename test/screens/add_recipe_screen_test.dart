import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/l10n/app_localizations.dart';
import 'package:savorly/models/category.dart';
import 'package:savorly/screens/add_recipe_screen.dart';
import 'package:savorly/state/recipe_store.dart';

Widget _wrap(RecipeStore store) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: RecipeStoreScope(store: store, child: const AddRecipeScreen()),
);

void main() {
  late RecipeStore store;

  setUp(() {
    store = RecipeStore(
      initialRecipes: const [],
      categories: const [
        Category(id: 'Dinner', name: 'Dinner', emoji: '🍝'),
      ],
    );
  });

  testWidgets('submitting with an empty title shows a validation error', (tester) async {
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    // Description is required too, but title is the one under test here.
    await tester.enterText(find.widgetWithText(TextFormField, 'Description *'), 'A description long enough.');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ingredient'), 'Flour');
    await tester.enterText(find.widgetWithText(TextFormField, 'Describe this cooking step'), 'Mix it.');

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Publish Recipe'));
    await tester.tap(find.widgetWithText(FilledButton, 'Publish Recipe'));
    await tester.pumpAndSettle();

    expect(find.text('Title must be at least 3 characters'), findsOneWidget);
    expect(store.all, isEmpty);
  });

  testWidgets('filling every required field and publishing adds the recipe to the store', (tester) async {
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Recipe Name *'), 'Test Tacos');
    await tester.enterText(find.widgetWithText(TextFormField, 'Description *'), 'A description long enough.');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ingredient'), 'Tortilla');
    await tester.enterText(find.widgetWithText(TextFormField, 'Describe this cooking step'), 'Fill and fold.');

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Publish Recipe'));
    await tester.tap(find.widgetWithText(FilledButton, 'Publish Recipe'));
    await tester.pumpAndSettle();

    expect(store.all, hasLength(1));
    expect(store.all.first.title, 'Test Tacos');
  });

  testWidgets('tapping the remove button on the only ingredient row is disabled', (tester) async {
    await tester.pumpWidget(_wrap(store));
    await tester.pumpAndSettle();

    // There are 2 delete icon buttons visible by default (1 ingredient row, 1 step row/card),
    // both disabled since canRemove is false when exactly one draft remains.
    final deleteButtons = tester.widgetList<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(deleteButtons, isNotEmpty);
    for (final button in deleteButtons) {
      expect(button.onPressed, isNull);
    }
  });
}
