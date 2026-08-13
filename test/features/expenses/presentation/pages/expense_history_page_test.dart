import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/data/models/expense_model.dart';
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/presentation/pages/expense_history_page.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/history_empty_state.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

Future<
  ({
    FakeFirebaseFirestore firestore,
    String uid,
    ExpenseRepositoryImpl expenseRepository,
  })
>
_seed(WidgetTester tester, List<Expense> expenses) async {
  final firestore = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth(signedIn: true);
  final uid = auth.currentUser!.uid;
  final expenseRepository = ExpenseRepositoryImpl(
    ExpenseRemoteDataSource(firestore),
    auth,
  );
  final categoryRepository = CategoryRepositoryImpl(
    CategoryRemoteDataSource(firestore),
    auth,
  );
  await categoryRepository.seedDefaultsIfNeeded();
  for (final expense in expenses) {
    // Write directly, preserving the caller-chosen date (create() would
    // still work, but this keeps seeding terse for this test).
    await firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expense.id)
        .set(ExpenseModel.fromEntity(expense).toJson());
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExpenseHistoryPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return (firestore: firestore, uid: uid, expenseRepository: expenseRepository);
}

Expense _expense({
  required String id,
  required int minorUnits,
  required DateTime date,
}) {
  return Expense(
    id: id,
    amount: Money(minorUnits: minorUnits, currencyCode: 'MXN'),
    categoryId: 'cat_food',
    date: date,
    createdAt: date,
  );
}

void main() {
  testWidgets('renders expenses grouped by day with correct subtotals', (
    tester,
  ) async {
    await _seed(tester, [
      _expense(id: 'a', minorUnits: 500, date: DateTime(2026, 8, 10, 9)),
      _expense(id: 'b', minorUnits: 777, date: DateTime(2026, 8, 10, 18)),
      _expense(id: 'c', minorUnits: 250, date: DateTime(2026, 8, 9, 8)),
      _expense(id: 'd', minorUnits: 333, date: DateTime(2026, 8, 9, 20)),
    ]);

    // Day of the 10th: entries 5.00 / 7.77, subtotal 500+777=1277 → "12.77"
    expect(find.text('12.77'), findsOneWidget);
    expect(find.text('5.00'), findsOneWidget);
    expect(find.text('7.77'), findsOneWidget);
    // Day of the 9th: entries 2.50 / 3.33, subtotal 250+333=583 → "5.83"
    expect(find.text('5.83'), findsOneWidget);
    expect(find.text('2.50'), findsOneWidget);
    expect(find.text('3.33'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no expenses', (
    tester,
  ) async {
    await _seed(tester, const []);

    expect(find.byType(HistoryEmptyState), findsOneWidget);
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets(
    'swiping an entry removes it immediately with no dialog, shows a '
    'snackbar with Undo, and Undo restores it',
    (tester) async {
      final env = await _seed(tester, [
        _expense(id: 'a', minorUnits: 500, date: DateTime(2026, 8, 10, 9)),
        _expense(id: 'b', minorUnits: 111, date: DateTime(2026, 8, 10, 18)),
      ]);

      expect(find.text('5.00'), findsOneWidget);

      await tester.drag(
        find.ancestor(
          of: find.text('5.00'),
          matching: find.byType(Dismissible),
        ),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Gone from the view immediately, no confirmation dialog anywhere.
      expect(find.text('5.00'), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Undo'), findsOneWidget);

      // Still not written to Firestore — undo hasn't happened yet, but the
      // document must not be soft-deleted before the window expires either.
      final beforeUndo = await env.firestore
          .collection('users')
          .doc(env.uid)
          .collection('expenses')
          .doc('a')
          .get();
      expect(beforeUndo.data()!['deletedAt'], isNull);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('5.00'), findsOneWidget);
    },
  );

  testWidgets(
    'a historical expense referencing an archived category still resolves '
    'and renders it normally (007 US7)',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: true);
      final uid = auth.currentUser!.uid;
      final expenseRepository = ExpenseRepositoryImpl(
        ExpenseRemoteDataSource(firestore),
        auth,
      );
      final categoryRepository = CategoryRepositoryImpl(
        CategoryRemoteDataSource(firestore),
        auth,
      );
      await categoryRepository.seedDefaultsIfNeeded();
      final all = (await categoryRepository.getAll()).when(
        success: (value) => value,
        failed: (failure) => throw StateError('setup failed: $failure'),
      );
      final food = all.firstWhere((c) => c.nameKey == 'category_food');
      await categoryRepository.setActive(food.id, isActive: false);

      await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc('a')
          .set(
            ExpenseModel.fromEntity(
              Expense(
                id: 'a',
                amount: const Money(minorUnits: 500, currencyCode: 'MXN'),
                categoryId: food.id,
                date: DateTime(2026, 8, 10, 9),
                createdAt: DateTime(2026, 8, 10, 9),
              ),
            ).toJson(),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(expenseRepository),
            categoryRepositoryProvider.overrideWithValue(categoryRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ExpenseHistoryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Resolved by name/icon, not the raw categoryId fallback.
      expect(find.text('Food'), findsOneWidget);
      expect(find.text(food.id), findsNothing);
    },
  );
}
