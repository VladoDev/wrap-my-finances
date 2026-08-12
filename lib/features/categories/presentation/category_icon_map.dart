import 'package:flutter/material.dart';

/// Maps a category's `iconName` (a stable string key, never a dynamic
/// lookup — `docs/DATA_MODEL.md`) to its bundled Material icon. Kept in
/// `presentation/` since `IconData` is a Flutter type; `data/`'s
/// `default_categories.dart` only knows the string keys.
const Map<String, IconData> categoryIconMap = {
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'shopping_bag': Icons.shopping_bag,
  'movie': Icons.movie,
  'medical_services': Icons.medical_services,
  'home': Icons.home,
  'category': Icons.category,
};

/// Fallback for an unrecognized `iconName` — should never occur for a
/// category this app itself seeded, but keeps the picker rendering
/// defensively rather than throwing on a display concern.
const IconData categoryIconFallback = Icons.category;

/// Resolves [iconName] to its icon, or [categoryIconFallback] if
/// unrecognized.
IconData resolveCategoryIcon(String iconName) =>
    categoryIconMap[iconName] ?? categoryIconFallback;
