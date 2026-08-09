import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';

Category _buildCategory({String? nameKey, String? name}) {
  return Category(
    id: 'cat_1',
    color: '#FF5722',
    iconName: 'restaurant',
    isDefault: nameKey != null,
    sortOrder: 1,
    isActive: true,
    usageCount: 0,
    nameKey: nameKey,
    name: name,
  );
}

void main() {
  test('constructs a valid default category with nameKey and no name', () {
    final category = _buildCategory(nameKey: 'category_food');

    expect(category.nameKey, 'category_food');
    expect(category.name, isNull);
  });

  test('constructs a valid user category with name and no nameKey', () {
    final category = _buildCategory(name: 'Side Hustle');

    expect(category.name, 'Side Hustle');
    expect(category.nameKey, isNull);
  });

  test('throws ArgumentError when both nameKey and name are set', () {
    expect(
      () => _buildCategory(nameKey: 'category_food', name: 'Side Hustle'),
      throwsArgumentError,
    );
  });

  test('throws ArgumentError when neither nameKey nor name is set', () {
    expect(_buildCategory, throwsArgumentError);
  });
}
