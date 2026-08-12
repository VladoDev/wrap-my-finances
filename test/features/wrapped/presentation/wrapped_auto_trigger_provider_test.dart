import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';
import 'package:wrap_my_finances/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:wrap_my_finances/features/wrapped/domain/entities/wrapped_summary.dart';
import 'package:wrap_my_finances/features/wrapped/domain/repositories/wrapped_repository.dart';
import 'package:wrap_my_finances/features/wrapped/domain/usecases/wrapped_trigger_decision.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/wrapped_auto_trigger_provider.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockWrappedRepository extends Mock implements WrappedRepository {}

WrappedSummary _summary({required bool isSyncing, required int count}) {
  return WrappedSummary(
    monthKey: previousMonthKey(DateTime.now()),
    isSyncing: isSyncing,
    total: const Money(minorUnits: 0, currencyCode: 'MXN'),
    topCategoryId: count > 0 ? 'cat_food' : null,
    topCategoryExpenseCount: count,
    biggestExpense: count > 0
        ? const Money(minorUnits: 100, currencyCode: 'MXN')
        : null,
    expenseCount: count,
  );
}

void main() {
  late _MockUserProfileRepository userProfileRepository;
  late _MockWrappedRepository wrappedRepository;
  late ProviderContainer container;

  setUp(() {
    userProfileRepository = _MockUserProfileRepository();
    wrappedRepository = _MockWrappedRepository();
    container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(
          userProfileRepository,
        ),
        wrappedRepositoryProvider.overrideWithValue(wrappedRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'resolves to the previous month key when the decision is autoShow',
    () async {
      when(() => userProfileRepository.watchProfile()).thenAnswer(
        (_) => Stream.value(
          const UserProfile(uid: 'u1', timeZone: 'America/Mexico_City'),
        ),
      );
      when(
        () => wrappedRepository.getSummary(any()),
      ).thenAnswer((_) async => Success(_summary(isSyncing: false, count: 5)));

      final result = await container.read(wrappedAutoTriggerProvider.future);

      expect(result, previousMonthKey(DateTime.now()));
    },
  );

  test('resolves to null when the decision is offerSuppressedCard', () async {
    when(() => userProfileRepository.watchProfile()).thenAnswer(
      (_) => Stream.value(
        const UserProfile(uid: 'u1', timeZone: 'America/Mexico_City'),
      ),
    );
    when(
      () => wrappedRepository.getSummary(any()),
    ).thenAnswer((_) async => Success(_summary(isSyncing: false, count: 2)));

    final result = await container.read(wrappedAutoTriggerProvider.future);

    expect(result, isNull);
  });

  test('resolves to null when the month was already marked seen', () async {
    final monthKey = previousMonthKey(DateTime.now());
    when(() => userProfileRepository.watchProfile()).thenAnswer(
      (_) => Stream.value(
        UserProfile(
          uid: 'u1',
          timeZone: 'America/Mexico_City',
          wrappedLastSeenMonth: monthKey,
        ),
      ),
    );
    when(
      () => wrappedRepository.getSummary(any()),
    ).thenAnswer((_) async => Success(_summary(isSyncing: false, count: 20)));

    final result = await container.read(wrappedAutoTriggerProvider.future);

    expect(result, isNull);
  });

  test('resolves to null when the summary fetch fails', () async {
    when(() => userProfileRepository.watchProfile()).thenAnswer(
      (_) => Stream.value(
        const UserProfile(uid: 'u1', timeZone: 'America/Mexico_City'),
      ),
    );
    when(() => wrappedRepository.getSummary(any())).thenAnswer(
      (_) async => Failed(UnknownFailure(Exception('boom'), StackTrace.empty)),
    );

    final result = await container.read(wrappedAutoTriggerProvider.future);

    expect(result, isNull);
  });
}
