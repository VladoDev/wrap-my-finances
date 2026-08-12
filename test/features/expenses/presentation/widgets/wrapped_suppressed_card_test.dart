import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/wrapped_suppressed_card.dart';
import 'package:wrap_my_finances/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late _MockUserProfileRepository userProfileRepository;
  late GoRouter router;
  late List<String> visitedLocations;

  setUp(() {
    userProfileRepository = _MockUserProfileRepository();
    when(
      () => userProfileRepository.markWrappedSeen(any()),
    ).thenAnswer((_) async => const Success(null));
    visitedLocations = [];
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            visitedLocations.add(state.uri.toString());
            return const Scaffold(
              body: WrappedSuppressedCard(monthKey: '2026-07'),
            );
          },
        ),
        GoRoute(
          path: '/wrapped/:monthKey',
          builder: (context, state) {
            visitedLocations.add(state.uri.toString());
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            userProfileRepository,
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

  testWidgets('renders the title and call-to-action', (tester) async {
    await pump(tester);

    expect(find.text('Curious about last month?'), findsOneWidget);
    expect(find.text('See your summary'), findsOneWidget);
  });

  testWidgets(
    'dismissing calls markWrappedSeen and hides the card without navigating',
    (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      verify(() => userProfileRepository.markWrappedSeen('2026-07')).called(1);
      expect(find.text('Curious about last month?'), findsNothing);
      expect(visitedLocations, ['/']);
    },
  );

  testWidgets('tapping the card navigates to /wrapped/:monthKey', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('See your summary'));
    await tester.pumpAndSettle();

    expect(visitedLocations, ['/', '/wrapped/2026-07']);
  });
}
