/// The subset of `users/{userId}` (see `docs/DATA_MODEL.md` §1) this
/// feature actually reads or writes. Deliberately does not model
/// `currencyCode`/`locale`/`defaultCategoryId`/`hapticsEnabled` — those
/// remain `004`'s `DeviceLocaleDefaults` interim and Phase 3 Settings'
/// concern respectively. See `specs/006-monthly-wrapped-summary/data-model.md`
/// §1.
class UserProfile {
  /// Creates a user profile.
  const UserProfile({
    required this.uid,
    required this.timeZone,
    this.wrappedLastSeenMonth,
  });

  /// Matches the Firebase Auth uid; immutable.
  final String uid;

  /// IANA identifier. Defaulted at profile-creation time from the device's
  /// current locale — not user-editable until Settings (Phase 3) exists.
  final String timeZone;

  /// `"YYYY-MM"`, or `null` if no Wrapped has ever been marked seen.
  final String? wrappedLastSeenMonth;
}
