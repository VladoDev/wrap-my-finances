import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';

/// Domain contract for the `users/{userId}` document — no feature wrote to
/// this path before `006`; see
/// `specs/006-monthly-wrapped-summary/research.md` #1.
abstract class UserProfileRepository {
  /// Creates `users/{uid}` with a device-locale-derived `timeZone` and
  /// `wrappedLastSeenMonth: null` if it doesn't exist yet. No-op if it
  /// does. Idempotent — safe to call on every launch. Requires an
  /// authenticated uid (call via `AuthRepository.runWhenAuthenticated`).
  Future<Result<void>> ensureExists();

  /// Live view of the current user's profile. Emits after `ensureExists()`
  /// has created the document, so callers never observe a "does not exist
  /// yet" state once subscribed post-bootstrap.
  Stream<UserProfile> watchProfile();

  /// Sets `wrappedLastSeenMonth` to [monthKey]. Called only when Wrapped
  /// (auto-shown or opened from the suppressed card) is actually dismissed
  /// — never merely from evaluating the trigger. See
  /// `specs/006-monthly-wrapped-summary/data-model.md` §4.
  Future<Result<void>> markWrappedSeen(String monthKey);
}
