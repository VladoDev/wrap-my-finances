import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';

void main() {
  test(
    'constructs from minorUnits and currencyCode with no Flutter/Firebase dependency',
    () {
      const money = Money(minorUnits: 15000, currencyCode: 'MXN');

      expect(money.minorUnits, 15000);
      expect(money.currencyCode, 'MXN');
    },
  );

  test('two Money values with the same fields are equal', () {
    const a = Money(minorUnits: 100, currencyCode: 'USD');
    const b = Money(minorUnits: 100, currencyCode: 'USD');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('Money values with different fields are not equal', () {
    const a = Money(minorUnits: 100, currencyCode: 'USD');
    const b = Money(minorUnits: 200, currencyCode: 'USD');

    expect(a, isNot(b));
  });
}
