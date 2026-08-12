import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wrap_my_finances/core/analytics/analytics_service.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/instrumentation/app_launch_clock.dart';
import 'package:wrap_my_finances/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/log_expense.dart';
import 'package:wrap_my_finances/features/expenses/presentation/pages/expense_capture_page.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/amount_display.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// Records calls instead of sending them anywhere — no real network, no
/// real Firebase project.
class _FakeAnalyticsService implements AnalyticsService {
  final List<Duration> loggedDurations = [];

  @override
  void logExpenseTimeToLog(Duration elapsed) => loggedDurations.add(elapsed);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'typing an amount, tapping Next, then a category persists the expense, '
    'increments the category usage count, resets the screen, and reports '
    'exactly one timing event — all against fakes, no real network',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(signedIn: true);
      final uid = auth.currentUser!.uid;

      final authRepository = FirebaseAuthRepository(auth);
      final expenseRepository = ExpenseRepositoryImpl(
        ExpenseRemoteDataSource(firestore),
        auth,
      );
      final categoryRepository = CategoryRepositoryImpl(
        CategoryRemoteDataSource(firestore),
        auth,
      );
      final analyticsService = _FakeAnalyticsService();
      final logExpense = LogExpense(
        authRepository,
        expenseRepository,
        categoryRepository,
        AppLaunchClock(DateTime.now()),
        analyticsService,
      );

      // Seeding normally happens fire-and-forget from bootstrap() — done
      // directly here so the picker has categories the moment it opens.
      await categoryRepository.seedDefaultsIfNeeded();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(expenseRepository),
            categoryRepositoryProvider.overrideWithValue(categoryRepository),
            logExpenseProvider.overrideWithValue(logExpense),
            deviceLanguageCodeProvider.overrideWithValue('en'),
            appEnvironmentProvider.overrideWithValue(AppEnvironment.prod),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ExpenseCapturePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type "5" — $5.00, one tap.
      await tester.tap(find.text('5'));
      await tester.pump();

      // Tap "Next" — one tap, opens the category sheet.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap the "Food" category tile — second and final tap.
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // The expense was persisted with the exact typed amount.
      final expenses = await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();
      expect(expenses.docs, hasLength(1));
      expect(expenses.docs.single.data()['amountMinor'], 500);

      // The category's usage count was incremented.
      final categories = await firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .where('nameKey', isEqualTo: 'category_food')
          .get();
      expect(categories.docs.single.data()['usageCount'], 1);

      // The screen reset to its initial, empty state.
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );

      // Exactly one timing event was reported — no financial data possible,
      // since AnalyticsService's only method takes a Duration.
      expect(analyticsService.loggedDurations, hasLength(1));
    },
  );
}
