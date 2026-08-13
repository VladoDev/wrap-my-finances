import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/expenses/data/device_locale_defaults.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';

/// Not in `lib/core/di/providers.dart` despite matching that file's bridge
/// pattern otherwise: it needs `DeviceLocaleDefaults`, a `features/expenses/
/// data/` internal, and `core/` must never import a feature's `data/`
/// (Constitution Principle 4) — only `features/expenses/presentation/`
/// itself is allowed to reach into its own feature's `data/` this way.
final _userProfileStreamProvider = StreamProvider<UserProfile>((ref) {
  return ref.watch(userProfileRepositoryProvider).watchProfile();
});

/// The user's current `currencyCode` preference, exposed as a synchronous
/// value backed by an already-live stream (`research.md` #5) — read once
/// via `ref.watch`/`ref.read` here, never awaited, so the capture path
/// (Constitution Principle 1) never blocks on it. Falls back to
/// [DeviceLocaleDefaults.currencyCodeFor] for the brief window before the
/// profile has loaded even once, or if no preference has ever been
/// explicitly set.
final currentCurrencyCodeProvider = Provider<String>((ref) {
  final storedCode = ref
      .watch(_userProfileStreamProvider)
      .valueOrNull
      ?.currencyCode;
  if (storedCode != null) return storedCode;
  return DeviceLocaleDefaults.currencyCodeFor(
    ref.watch(deviceLanguageCodeProvider),
  );
});
