import 'package:wrap_my_finances/features/user_profile/domain/entities/user_profile.dart';

/// Firestore document shape for the fields this feature reads/writes on
/// `users/{userId}`, per `docs/DATA_MODEL.md` §1 and
/// `specs/006-monthly-wrapped-summary/data-model.md` §3. Tolerant of the
/// document's other documented fields (`createdAt`, `lastLogin`,
/// `isAnonymous`, `currencyCode`, `locale`, `defaultCategoryId`,
/// `hapticsEnabled`, `schemaVersion`) being present but unmodeled — this
/// feature doesn't populate or need them.
class UserProfileModel {
  /// Creates a model with every field this feature cares about explicit.
  const UserProfileModel({
    required this.uid,
    required this.timeZone,
    this.wrappedLastSeenMonth,
  });

  /// Reconstructs a model from a Firestore document snapshot's data.
  factory UserProfileModel.fromJson(Map<String, Object?> json) {
    return UserProfileModel(
      uid: json['uid']! as String,
      timeZone: json['timeZone']! as String,
      wrappedLastSeenMonth: json['wrappedLastSeenMonth'] as String?,
    );
  }

  /// Matches the Firebase Auth uid.
  final String uid;

  /// IANA time zone identifier.
  final String timeZone;

  /// `"YYYY-MM"`, or `null`.
  final String? wrappedLastSeenMonth;

  /// The write payload for creating the document — only the three fields
  /// this feature populates, per `data-model.md` §3 and
  /// `contracts/security-rules-delta.md`'s `isValidUserProfile()`.
  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'timeZone': timeZone,
      'wrappedLastSeenMonth': wrappedLastSeenMonth,
    };
  }

  /// Converts to the domain entity.
  UserProfile toEntity() {
    return UserProfile(
      uid: uid,
      timeZone: timeZone,
      wrappedLastSeenMonth: wrappedLastSeenMonth,
    );
  }
}
