import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/models/category.dart';

void main() {
  test('Category.fromJson parses id, name, emoji', () {
    final category = Category.fromJson({
      'id': 'Breakfast',
      'name': 'Breakfast',
      'emoji': '🥞',
    });
    expect(category.id, 'Breakfast');
    expect(category.name, 'Breakfast');
    expect(category.emoji, '🥞');
  });
}
