import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_result.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/delete_account.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/link_account.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/settings/presentation/widgets/settings_account_section.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockExpenseRepository expenseRepository;
  late _MockCategoryRepository categoryRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
    expenseRepository = _MockExpenseRepository();
    categoryRepository = _MockCategoryRepository();
    when(() => authRepository.isLinked).thenReturn(false);
    when(() => authRepository.linkedProviderLabel).thenReturn(null);
    when(
      () => authRepository.linkWithGoogle(),
    ).thenAnswer((_) async => const LinkSucceeded());
    when(
      () => authRepository.linkWithApple(),
    ).thenAnswer((_) async => const LinkSucceeded());
    when(
      () => authRepository.deleteAccount(
        onReauthRequired: any(named: 'onReauthRequired'),
      ),
    ).thenAnswer((_) async => const Success(null));
    when(() => authRepository.ensureSignedIn()).thenAnswer((_) async => 'uid');
  });

  Future<void> pump(WidgetTester tester) {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('capture')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const Scaffold(body: SettingsAccountSection()),
        ),
        GoRoute(
          path: '/link-conflict',
          builder: (context, state) => const Scaffold(body: Text('conflict')),
        ),
      ],
    );
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          linkAccountUseCaseProvider.overrideWithValue(
            LinkAccountUseCase(
              authRepository,
              expenseRepository,
              categoryRepository,
            ),
          ),
          deleteAccountUseCaseProvider.overrideWithValue(
            DeleteAccountUseCase(authRepository),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgets(
    'renders a link CTA with Google and Apple options when unlinked',
    (tester) async {
      await pump(tester);

      expect(find.text('Link an account'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
    },
  );

  testWidgets('tapping Google invokes AuthRepository.linkWithGoogle', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    verify(() => authRepository.linkWithGoogle()).called(1);
    verifyNever(() => authRepository.linkWithApple());
  });

  testWidgets('tapping Apple invokes AuthRepository.linkWithApple', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Continue with Apple'));
    await tester.pump();

    verify(() => authRepository.linkWithApple()).called(1);
    verifyNever(() => authRepository.linkWithGoogle());
  });

  testWidgets('shows the linked status instead of the CTA once linked', (
    tester,
  ) async {
    when(() => authRepository.isLinked).thenReturn(true);
    when(() => authRepository.linkedProviderLabel).thenReturn('Google');

    await pump(tester);

    expect(find.text('Linked via Google'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Continue with Apple'), findsNothing);
  });

  testWidgets(
    'on a NetworkFailure result, shows the offline message and returns to '
    'its normal (not-linked, not stuck loading) state',
    (tester) async {
      when(
        () => authRepository.linkWithGoogle(),
      ).thenAnswer((_) async => const LinkFailed(NetworkFailure()));

      await pump(tester);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text("Can't link right now — you're offline"),
        findsOneWidget,
      );
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
    },
  );

  group('account deletion (007 US6)', () {
    testWidgets('a single tap never deletes anything', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Delete account'));
      await tester.pump();

      verifyNever(
        () => authRepository.deleteAccount(
          onReauthRequired: any(named: 'onReauthRequired'),
        ),
      );
      expect(find.text('Delete your account?'), findsOneWidget);
    });

    testWidgets(
      'requires a distinct explicit confirmation before deleting',
      (tester) async {
        await pump(tester);

        await tester.tap(find.text('Delete account'));
        await tester.pumpAndSettle();
        // The dialog's own "Delete account" action button, not the
        // original CTA behind it.
        await tester.tap(find.text('Delete account').last);
        await tester.pumpAndSettle();

        verify(
          () => authRepository.deleteAccount(
            onReauthRequired: any(named: 'onReauthRequired'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'cancelling the confirmation dialog deletes nothing',
      (tester) async {
        await pump(tester);

        await tester.tap(find.text('Delete account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        verifyNever(
          () => authRepository.deleteAccount(
            onReauthRequired: any(named: 'onReauthRequired'),
          ),
        );
        expect(find.text('Delete your account?'), findsNothing);
      },
    );
  });
}
