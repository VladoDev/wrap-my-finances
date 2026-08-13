import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/settings/presentation/widgets/currency_picker.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';
import 'package:wrap_my_finances/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late _MockUserProfileRepository userProfileRepository;

  setUp(() {
    userProfileRepository = _MockUserProfileRepository();
    when(() => userProfileRepository.watchProfile()).thenAnswer(
      (_) => Stream.value(
        const UserProfile(uid: 'u1', timeZone: 'America/Mexico_City'),
      ),
    );
    when(
      () => userProfileRepository.updateCurrencyCode(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(
            userProfileRepository,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: CurrencyPicker()),
        ),
      ),
    );
  }

  testWidgets(
    'selecting a value calls updateCurrencyCode with the chosen value',
    (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EUR').last);
      await tester.pumpAndSettle();

      verify(() => userProfileRepository.updateCurrencyCode('EUR')).called(1);
    },
  );
}
