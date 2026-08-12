import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/features/expenses/presentation/controllers/amount_input_state.dart';

void main() {
  group('basic accumulation (US1)', () {
    test('appending digits accumulates minorUnits', () {
      var state = const AmountInputState(locale: 'en');
      state = state.appendDigit('1').appendDigit('2').appendDigit('3');
      expect(state.minorUnits, 12300);
    });

    test('isValid is false at zero and true once non-zero', () {
      const empty = AmountInputState(locale: 'en');
      expect(empty.isValid, isFalse);

      final zero = empty.appendDigit('0').appendDigit('0');
      expect(zero.isValid, isFalse);

      final nonZero = empty.appendDigit('5');
      expect(nonZero.isValid, isTrue);
    });
  });

  group('decimal and grouping rules (US2)', () {
    test('a decimal digit is added after the separator', () {
      final state = const AmountInputState(
        locale: 'en',
      ).appendDigit('1').appendDecimalSeparator().appendDigit('5');
      expect(state.minorUnits, 150); // "1.5" reads as $1.50, like any decimal
    });

    test('a second decimal separator is ignored', () {
      final state = const AmountInputState(locale: 'en')
          .appendDigit('1')
          .appendDecimalSeparator()
          .appendDigit('5')
          .appendDecimalSeparator()
          .appendDigit('6');
      expect(state.minorUnits, 156); // the second separator never landed
    });

    test('a third decimal digit is ignored', () {
      final state = const AmountInputState(locale: 'en')
          .appendDigit('1')
          .appendDecimalSeparator()
          .appendDigit('2')
          .appendDigit('3')
          .appendDigit('4');
      expect(state.minorUnits, 123); // the "4" never landed
    });

    test('input freezes at the 1,000,000.00 ceiling', () {
      var state = const AmountInputState(locale: 'en');
      for (final digit in '1000000'.split('')) {
        state = state.appendDigit(digit);
      }
      expect(state.minorUnits, 100000000); // $1,000,000.00 exactly
      // One more digit would exceed the ceiling — ignored.
      state = state.appendDigit('1');
      expect(state.minorUnits, 100000000);
    });

    test('backspace on an empty amount is a no-op', () {
      const state = AmountInputState(locale: 'en');
      expect(state.backspace().minorUnits, 0);
      expect(identical(state.backspace(), state), isTrue);
    });

    test(
      'backspace removes a decimal digit, then the separator, then an '
      'integer digit',
      () {
        var state = const AmountInputState(
          locale: 'en',
        ).appendDigit('1').appendDecimalSeparator().appendDigit('5');
        expect(state.formattedDisplay, '1.5');

        state = state.backspace();
        expect(state.formattedDisplay, '1.');

        state = state.backspace();
        expect(state.formattedDisplay, '1');

        state = state.backspace();
        expect(state.formattedDisplay, '0');
      },
    );

    test('grouping separators match the active locale', () {
      var enState = const AmountInputState(locale: 'en');
      for (final digit in '12345'.split('')) {
        enState = enState.appendDigit(digit);
      }
      expect(enState.formattedDisplay, '12,345');

      var frState = const AmountInputState(locale: 'fr');
      for (final digit in '12345'.split('')) {
        frState = frState.appendDigit(digit);
      }
      expect(frState.formattedDisplay, '12 345');
    });

    test(
      'the locale decimal separator symbol is used for es/fr, not a period',
      () {
        final state = const AmountInputState(
          locale: 'es',
        ).appendDigit('1').appendDecimalSeparator().appendDigit('5');
        expect(state.formattedDisplay, '1,5');
      },
    );
  });
}
