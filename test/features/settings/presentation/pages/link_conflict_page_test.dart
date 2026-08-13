import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict_resolution.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/settings/presentation/pages/link_conflict_page.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository authRepository;
  const conflict = LinkConflict(existingProviderLabel: 'Google');

  setUpAll(() {
    registerFallbackValue(LinkConflictResolution.merge);
    registerFallbackValue(const LinkConflict(existingProviderLabel: ''));
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    when(() => authRepository.isLinked).thenReturn(true);
    when(() => authRepository.linkedProviderLabel).thenReturn('Google');
    when(
      () => authRepository.resolveLinkConflict(any(), any()),
    ).thenAnswer((_) async => const Success(null));
  });

  Future<void> pump(WidgetTester tester) {
    final router = GoRouter(
      initialLocation: '/link-conflict',
      routes: [
        GoRoute(
          path: '/link-conflict',
          builder: (context, state) =>
              const LinkConflictPage(conflict: conflict),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('settings')),
        ),
      ],
    );
    return tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgets('renders both options with no default/pre-selected choice', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('This account already has data'), findsOneWidget);
    expect(find.text('Combine both histories'), findsOneWidget);
    expect(find.text("Keep only this account's history"), findsOneWidget);
    verifyNever(() => authRepository.resolveLinkConflict(any(), any()));
  });

  testWidgets(
    'tapping discard shows a distinct confirmation naming what will be '
    'discarded before it proceeds',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text("Keep only this account's history"));
      await tester.pumpAndSettle();

      expect(find.text("Discard this device's data?"), findsOneWidget);
      expect(
        find.text(
          'Everything logged on this device will be permanently deleted. '
          "This account's existing history will be kept.",
        ),
        findsOneWidget,
      );
      verifyNever(() => authRepository.resolveLinkConflict(any(), any()));
    },
  );

  testWidgets(
    'confirming the discard dialog calls resolveLinkConflict with '
    'discardLocal',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text("Keep only this account's history"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Keep only this account's history").last);
      await tester.pumpAndSettle();

      verify(
        () => authRepository.resolveLinkConflict(
          conflict,
          LinkConflictResolution.discardLocal,
        ),
      ).called(1);
    },
  );

  testWidgets(
    'tapping merge proceeds directly, with no confirmation step',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('Combine both histories'));
      await tester.pumpAndSettle();

      verify(
        () => authRepository.resolveLinkConflict(
          conflict,
          LinkConflictResolution.merge,
        ),
      ).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
