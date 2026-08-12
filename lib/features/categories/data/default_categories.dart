/// One row of the fixed default-category seed table from
/// `specs/004-quick-expense-capture/data-model.md`. Adding an eighth
/// default category means adding one row here, one entry in
/// `category_icon_map.dart`, one branch in `category_name_resolver.dart`,
/// and one key in all five ARB files.
class DefaultCategorySeed {
  /// Creates a seed row.
  const DefaultCategorySeed({
    required this.nameKey,
    required this.iconName,
    required this.sortOrder,
  });

  /// Firestore `nameKey` value — snake_case, matches an ARB key resolved by
  /// `category_name_resolver.dart` (see data-model.md's naming note).
  final String nameKey;

  /// Key into `category_icon_map.dart`.
  final String iconName;

  /// Seed order — also the tie-break key when `usageCount` ties, and the
  /// index into `AppColorsExtension.categoryPalette`.
  final int sortOrder;
}

/// The seven default categories this feature seeds on first launch.
const List<DefaultCategorySeed> defaultCategorySeeds = [
  DefaultCategorySeed(
    nameKey: 'category_food',
    iconName: 'restaurant',
    sortOrder: 1,
  ),
  DefaultCategorySeed(
    nameKey: 'category_transport',
    iconName: 'directions_car',
    sortOrder: 2,
  ),
  DefaultCategorySeed(
    nameKey: 'category_shopping',
    iconName: 'shopping_bag',
    sortOrder: 3,
  ),
  DefaultCategorySeed(
    nameKey: 'category_entertainment',
    iconName: 'movie',
    sortOrder: 4,
  ),
  DefaultCategorySeed(
    nameKey: 'category_health',
    iconName: 'medical_services',
    sortOrder: 5,
  ),
  DefaultCategorySeed(
    nameKey: 'category_housing',
    iconName: 'home',
    sortOrder: 6,
  ),
  DefaultCategorySeed(
    nameKey: 'category_other',
    iconName: 'category',
    sortOrder: 7,
  ),
];
