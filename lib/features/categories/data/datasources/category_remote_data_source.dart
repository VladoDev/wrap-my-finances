import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color;
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_colors.dart';
import 'package:wrap_my_finances/features/categories/data/default_categories.dart';
import 'package:wrap_my_finances/features/categories/data/models/category_model.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';

/// Category persistence over Firestore: seeding, active-category queries,
/// and usage-frequency bookkeeping.
@injectable
class CategoryRemoteDataSource {
  /// Creates a data source over the injected `FirebaseFirestore` instance.
  CategoryRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> _categoriesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('categories');

  /// Seeds the default category set for [userId] if none exist yet.
  /// Idempotent at the data level (checks for any existing document first);
  /// the repository additionally memoizes this per process — see
  /// research.md.
  Future<void> seedDefaultsIfNeeded(String userId) async {
    final ref = _categoriesRef(userId);
    final existing = await ref.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final palette = AppColorsExtension.light.categoryPalette;
    final batch = _firestore.batch();
    for (final seed in defaultCategorySeeds) {
      final docRef = ref.doc();
      final category = Category(
        id: docRef.id,
        nameKey: seed.nameKey,
        color: _colorToHex(palette[seed.sortOrder - 1]),
        iconName: seed.iconName,
        isDefault: true,
        sortOrder: seed.sortOrder,
        isActive: true,
        usageCount: 0,
      );
      batch.set(docRef, CategoryModel.fromEntity(category).toJson());
    }

    // Fire the batch write; confirm it landed locally the same way
    // ExpenseRemoteDataSource does, rather than waiting on server ack.
    final writeFuture = batch.commit();
    final localConfirmed = ref.snapshots().firstWhere(
      (snapshot) => snapshot.docs.length >= defaultCategorySeeds.length,
    );
    await Future.any<Object?>([localConfirmed, writeFuture]);
    unawaited(writeFuture.catchError((Object _, StackTrace _) {}));
  }

  static String _colorToHex(Color color) {
    final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${argb.substring(2).toUpperCase()}';
  }

  /// One-shot fetch of active categories, ordered by `usageCount`
  /// descending, tie-broken by `sortOrder` ascending (data-model.md).
  Future<List<Category>> getActive(String userId) async {
    final snapshot = await _activeQuery(userId).get();
    return _toEntities(snapshot.docs);
  }

  /// Live query, same ordering as [getActive].
  Stream<List<Category>> watchActive(String userId) {
    return _activeQuery(userId).snapshots().map((s) => _toEntities(s.docs));
  }

  // Matches firestore.indexes.json's existing categories composite index
  // (isActive ASC, usageCount DESC) exactly — no index change needed. The
  // sortOrder tie-break is applied client-side below instead of as a third
  // orderBy(), which would require widening that index.
  Query<Map<String, Object?>> _activeQuery(String userId) {
    return _categoriesRef(userId)
        .where('isActive', isEqualTo: true)
        .orderBy('usageCount', descending: true);
  }

  List<Category> _toEntities(
    List<QueryDocumentSnapshot<Map<String, Object?>>> docs,
  ) {
    final categories = docs
        .map((doc) => CategoryModel.fromJson(doc.id, doc.data()).toEntity())
        .toList();
    // Stable sort: Firestore guarantees usageCount-descending order but not
    // a deterministic order among ties, so break ties by sortOrder here.
    return categories..sort((a, b) {
      final byUsage = b.usageCount.compareTo(a.usageCount);
      return byUsage != 0 ? byUsage : a.sortOrder.compareTo(b.sortOrder);
    });
  }

  /// Bumps `usageCount` and `lastUsedAt` for [categoryId], keeping frequency
  /// ordering accurate after a log.
  Future<void> incrementUsage(String userId, String categoryId) {
    return _categoriesRef(userId).doc(categoryId).update({
      'usageCount': FieldValue.increment(1),
      'lastUsedAt': FieldValue.serverTimestamp(),
    });
  }
}
