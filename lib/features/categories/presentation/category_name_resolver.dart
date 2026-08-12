import 'package:flutter/widgets.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// Resolves [category]'s display name: the literal [Category.name] for a
/// user-created category, or the localized string for a default category's
/// [Category.nameKey], resolved via [context] — the one place
/// `AppLocalizations` is touched for categories, per
/// `docs/ARCHITECTURE.md`'s "resolving [a nameKey] to display text happens
/// in the widget tree" rule.
///
/// Throws [ArgumentError] for an unrecognized `nameKey` — that can only
/// originate from this app's own seeding code, never user input, so an
/// unrecognized value is a programmer error, not a runtime condition to
/// swallow (the same style `Category`'s own constructor uses for its
/// invariant).
String resolveCategoryName(BuildContext context, Category category) {
  final name = category.name;
  if (name != null) return name;

  final l10n = AppLocalizations.of(context)!;
  return switch (category.nameKey) {
    'category_food' => l10n.categoryFood,
    'category_transport' => l10n.categoryTransport,
    'category_shopping' => l10n.categoryShopping,
    'category_entertainment' => l10n.categoryEntertainment,
    'category_health' => l10n.categoryHealth,
    'category_housing' => l10n.categoryHousing,
    'category_other' => l10n.categoryOther,
    final unrecognized => throw ArgumentError(
      'unrecognized category nameKey: $unrecognized',
    ),
  };
}
