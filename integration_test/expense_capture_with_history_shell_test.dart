import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wrap_my_finances/app.dart';
import 'package:wrap_my_finances/core/analytics/analytics_service.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/instrumentation/app_launch_clock.dart';
import 'package:wrap_my_finances/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/data/datasources/expense_remote_data_source.dart';
import 'package:wrap_my_finances/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/log_expense.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/amount_display.dart';

/// Records calls instead of sending them anywhere — no real network.
class _FakeAnalyticsService implements AnalyticsService {
  final List<Duration> loggedDurations = [];

  @override
  void logExpenseTimeToLog(Duration elapsed) => loggedDurations.add(elapsed);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    "004's exact two-tap logging flow is unchanged with the full "
    'navigation shell (005) present in the tree: the floating nav bar '
    'adds no screen, dialog, or tap to the capture path',
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
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      // FR-001/FR-012: the app opens directly to capture, nav bar visible.
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('History'), findsOneWidget);

      // The exact same two taps 004 requires — Continuar then a category.
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      final expenses = await firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();
      expect(expenses.docs, hasLength(1));
      expect(expenses.docs.single.data()['amountMinor'], 500);
      expect(analyticsService.loggedDurations, hasLength(1));

      // Screen reset to its initial state, still on the capture route, nav
      // bar still present and unobstructed.
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('History'), findsOneWidget);

      // Navigating away and back doesn't change any of the above, and
      // reopening the app (a fresh pump) always lands back on capture —
      // covered structurally by _router's fixed initialLocation, exercised
      // here by simply confirming History is reachable and returns cleanly.
      await tester.tap(find.bySemanticsLabel('History'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Log expense'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Log expense'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AmountDisplay),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
    },
  );
}
