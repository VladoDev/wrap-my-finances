import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict_resolution.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_result.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/link_account.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockExpenseRepository expenseRepository;
  late _MockCategoryRepository categoryRepository;
  late LinkAccountUseCase useCase;
  const conflict = LinkConflict(existingProviderLabel: 'Google');

  setUpAll(() {
    registerFallbackValue(conflict);
    registerFallbackValue(LinkConflictResolution.discardLocal);
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    expenseRepository = _MockExpenseRepository();
    categoryRepository = _MockCategoryRepository();
    useCase = LinkAccountUseCase(
      authRepository,
      expenseRepository,
      categoryRepository,
    );
    when(
      () => authRepository.linkWithGoogle(),
    ).thenAnswer((_) async => const LinkConflictDetected(conflict));
  });

  Category defaultCategory() => Category(
    id: 'cat_food',
    nameKey: 'category_food',
    color: '#FF5722',
    iconName: 'restaurant',
    isDefault: true,
    sortOrder: 1,
    isActive: true,
    usageCount: 0,
  );

  Category userCategory() => Category(
    id: 'cat_custom',
    name: 'Side Hustle',
    color: '#00BFA5',
    iconName: 'briefcase',
    isDefault: false,
    sortOrder: 8,
    isActive: true,
    usageCount: 0,
  );

  group('empty local history (US2 — new device)', () {
    setUp(() {
      when(
        () => expenseRepository.watchAll(),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => categoryRepository.getAll(),
      ).thenAnswer((_) async => Success([defaultCategory()]));
      when(
        () => authRepository.resolveLinkConflict(any(), any()),
      ).thenAnswer((_) async => const Success(null));
    });

    test(
      'resolves the conflict as discardLocal automatically, without '
      'propagating LinkConflictDetected',
      () async {
        final result = await useCase(LinkProvider.google);

        expect(result, isA<LinkSucceeded>());
        verify(
          () => authRepository.resolveLinkConflict(
            conflict,
            LinkConflictResolution.discardLocal,
          ),
        ).called(1);
      },
    );
  });

  group('non-empty local history (US3 — existing behavior unchanged)', () {
    test('a non-empty expense list still propagates the conflict', () async {
      when(
        () => expenseRepository.watchAll(),
      ).thenAnswer(
        (_) => Stream.value([
          Expense(
            id: 'e1',
            amount: const Money(minorUnits: 500, currencyCode: 'MXN'),
            categoryId: 'cat_food',
            date: DateTime(2026, 8, 3),
            createdAt: DateTime(2026, 8, 3),
          ),
        ]),
      );
      when(
        () => categoryRepository.getAll(),
      ).thenAnswer((_) async => Success([defaultCategory()]));

      final result = await useCase(LinkProvider.google);

      expect(result, isA<LinkConflictDetected>());
      verifyNever(() => authRepository.resolveLinkConflict(any(), any()));
    });

    test(
      'a user-created category with no expenses still propagates the '
      'conflict',
      () async {
        when(
          () => expenseRepository.watchAll(),
        ).thenAnswer((_) => Stream.value(const []));
        when(() => categoryRepository.getAll()).thenAnswer(
          (_) async => Success([defaultCategory(), userCategory()]),
        );

        final result = await useCase(LinkProvider.google);

        expect(result, isA<LinkConflictDetected>());
        verifyNever(() => authRepository.resolveLinkConflict(any(), any()));
      },
    );
  });
}
