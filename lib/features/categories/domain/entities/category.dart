/// A spending category. Exactly one of [nameKey]/[name] is non-null —
/// enforced here so the invariant is impossible to violate from the client
/// side, mirroring the same invariant the Security Rules enforce
/// server-side (see `data-model.md`). [nameKey] is non-null only for
/// default categories (a translation key resolved at read time); [name] is
/// non-null only for user-created categories (literal text, never
/// translated).
class Category {
  /// Creates a category. Throws [ArgumentError] if [nameKey]/[name] don't
  /// satisfy the exactly-one-non-null invariant.
  Category({
    required this.id,
    required this.color,
    required this.iconName,
    required this.isDefault,
    required this.sortOrder,
    required this.isActive,
    required this.usageCount,
    this.nameKey,
    this.name,
    this.lastUsedAt,
  }) {
    if ((nameKey != null) == (name != null)) {
      throw ArgumentError(
        'exactly one of nameKey/name must be non-null '
        '(nameKey: $nameKey, name: $name)',
      );
    }
  }

  /// Firestore document identifier.
  final String id;

  /// Non-null only for default categories — a key into the app's ARB
  /// files.
  final String? nameKey;

  /// Non-null only for user-created categories — literal text, never
  /// translated.
  final String? name;

  /// `#RRGGBB`.
  final String color;

  /// Key into the app's bundled icon set.
  final String iconName;

  /// Whether this is a seeded default category.
  final bool isDefault;

  /// Manual sort position.
  final int sortOrder;

  /// Whether this category appears in the picker.
  final bool isActive;

  /// How many times this category has been used, for frequency ordering.
  final int usageCount;

  /// When this category was last used, if ever.
  final DateTime? lastUsedAt;
}
