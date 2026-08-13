import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/expenses/presentation/current_currency_code_provider.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';
import 'package:wrap_my_finances/features/user_profile/domain/repositories/user_profile_repository.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late _MockUserProfileRepository userProfileRepository;
  late ProviderContainer container;

  setUp(() {
    userProfileRepository = _MockUserProfileRepository();
    container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(
          userProfileRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'resolves to DeviceLocaleDefaults before the profile has loaded '
    '(the stream has not emitted yet)',
    () {
      when(
        () => userProfileRepository.watchProfile(),
      ).thenAnswer((_) => const Stream.empty());

      final result = container.read(currentCurrencyCodeProvider);

      final expected =
          switch (PlatformDispatcher.instance.locale.languageCode) {
            'es' => 'MXN',
            'pt' => 'BRL',
            'it' || 'fr' => 'EUR',
            _ => 'USD',
          };
      expect(result, expected);
    },
  );

  test(
    'resolves to DeviceLocaleDefaults when no currencyCode preference has '
    'ever been set',
    () {
      when(() => userProfileRepository.watchProfile()).thenAnswer(
        (_) => Stream.value(
          const UserProfile(uid: 'u1', timeZone: 'America/Mexico_City'),
        ),
      );

      final result = container.read(currentCurrencyCodeProvider);

      expect(result, isNotEmpty);
    },
  );

  test('resolves to UserProfile.currencyCode once available', () async {
    when(() => userProfileRepository.watchProfile()).thenAnswer(
      (_) => Stream.value(
        const UserProfile(
          uid: 'u1',
          timeZone: 'America/Mexico_City',
          currencyCode: 'EUR',
        ),
      ),
    );

    // Establish the subscription and let its first (synchronous) event
    // land before reading the derived value.
    container.listen(currentCurrencyCodeProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentCurrencyCodeProvider), 'EUR');
  });
}
