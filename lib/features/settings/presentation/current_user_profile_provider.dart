import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';

/// Live view of the current `UserProfile` — `CurrencyPicker`/`TimeZonePicker`
/// read the stored preference to show as pre-selected. A separate copy from
/// `features/expenses/presentation/current_currency_code_provider.dart`'s
/// own private stream provider, deliberately: features may only share
/// `domain/` contracts across boundaries (Constitution Principle 4), not
/// `presentation/`-layer providers.
final currentUserProfileProvider = StreamProvider<UserProfile>((ref) {
  return ref.watch(userProfileRepositoryProvider).watchProfile();
});
