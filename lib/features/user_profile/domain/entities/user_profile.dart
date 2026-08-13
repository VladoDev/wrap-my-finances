/// The subset of `users/{userId}` (see `docs/DATA_MODEL.md` §1) this
/// feature actually reads or writes. Deliberately does not model
/// `locale`/`defaultCategoryId`/`hapticsEnabled` — those remain out of
/// scope. See `specs/006-monthly-wrapped-summary/data-model.md` §1 and
/// `specs/007-account-linking-integrity/data-model.md` §1.
class UserProfile {
  /// Creates a user profile.
  const UserProfile({
    required this.uid,
    required this.timeZone,
    this.currencyCode,
    this.wrappedLastSeenMonth,
  });

  /// Matches the Firebase Auth uid; immutable.
  final String uid;

  /// IANA identifier. Defaulted at profile-creation time from the device's
  /// current locale, editable in Settings (`007`).
  final String timeZone;

  /// ISO 4217 code. `null` until explicitly set — editable in Settings
  /// (`007`). Changing it only affects expenses logged afterward; never
  /// rewrites a past expense's stored amount/currency
  /// (`docs/DATA_MODEL.md`, amended by `007`).
  final String? currencyCode;

  /// `"YYYY-MM"`, or `null` if no Wrapped has ever been marked seen.
  final String? wrappedLastSeenMonth;
}
