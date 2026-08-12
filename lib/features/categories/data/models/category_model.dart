import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';

/// Firestore document shape for a category, per `docs/DATA_MODEL.md`. Adds
/// `schemaVersion`, the one infrastructure-only field the domain `Category`
/// entity doesn't carry. `color` is already a `#RRGGBB` `String` on the
/// domain entity itself (per `003`) — any `Color`→hex conversion happens
/// once, at seed-construction time in `CategoryRemoteDataSource`, never
/// here.
class CategoryModel {
  /// Creates a model with every Firestore field explicit.
  const CategoryModel({
    required this.id,
    required this.nameKey,
    required this.name,
    required this.color,
    required this.iconName,
    required this.isDefault,
    required this.sortOrder,
    required this.isActive,
    required this.usageCount,
    required this.lastUsedAt,
  });

  /// Builds the write payload for [category].
  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      nameKey: category.nameKey,
      name: category.name,
      color: category.color,
      iconName: category.iconName,
      isDefault: category.isDefault,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
      usageCount: category.usageCount,
      lastUsedAt: category.lastUsedAt,
    );
  }

  /// Reconstructs a model from a Firestore document snapshot's data.
  factory CategoryModel.fromJson(String id, Map<String, Object?> json) {
    return CategoryModel(
      id: id,
      nameKey: json['nameKey'] as String?,
      name: json['name'] as String?,
      color: json['color']! as String,
      iconName: json['iconName']! as String,
      isDefault: json['isDefault']! as bool,
      sortOrder: json['sortOrder']! as int,
      isActive: json['isActive']! as bool,
      usageCount: json['usageCount']! as int,
      lastUsedAt: (json['lastUsedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestore document id.
  final String id;

  /// Non-null only for default categories.
  final String? nameKey;

  /// Non-null only for user-created categories.
  final String? name;

  /// `#RRGGBB`.
  final String color;

  /// Key into the app-side bundled icon map.
  final String iconName;

  /// Whether this is a seeded default category.
  final bool isDefault;

  /// Manual sort position — also the tie-break key when `usageCount` ties.
  final int sortOrder;

  /// Whether this category appears in the picker.
  final bool isActive;

  /// How many times this category has been used.
  final int usageCount;

  /// When this category was last used, if ever.
  final DateTime? lastUsedAt;

  /// The write payload.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
      'name': name,
      'color': color,
      'iconName': iconName,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'usageCount': usageCount,
      'lastUsedAt': lastUsedAt == null ? null : Timestamp.fromDate(lastUsedAt!),
      'schemaVersion': 1,
    };
  }

  /// Converts to the domain entity `003` defined.
  Category toEntity() {
    return Category(
      id: id,
      nameKey: nameKey,
      name: name,
      color: color,
      iconName: iconName,
      isDefault: isDefault,
      sortOrder: sortOrder,
      isActive: isActive,
      usageCount: usageCount,
      lastUsedAt: lastUsedAt,
    );
  }
}
