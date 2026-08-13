import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';

/// Domain contract for querying and updating categories. No implementation
/// exists yet — `004` builds `data/`/`presentation/` against this
/// interface. See `contracts/domain-repositories-api.md`.
abstract class CategoryRepository {
  /// One-shot fetch of active categories, ordered by `usageCount`
  /// descending (matches the Firestore index in `docs/DATA_MODEL.md`).
  Future<Result<List<Category>>> getActive();

  /// Live query of active categories, same ordering as [getActive].
  Stream<List<Category>> watchActive();

  /// Called after a category is used to log an expense, to keep frequency
  /// ordering accurate.
  Future<Result<void>> incrementUsage(String categoryId);

  /// Seeds the default category set if the user has none yet. Idempotent —
  /// safe to call on every app start. Requires an authenticated UID (call
  /// via `AuthRepository.runWhenAuthenticated`), since writing a category
  /// requires `isOwner(userId)`. Additive member introduced by `004` — see
  /// `specs/004-quick-expense-capture/contracts/expense-capture-api.md`.
  Future<Result<void>> seedDefaultsIfNeeded();

  /// Every category, active and archived — the Settings management screen's
  /// list. Distinct from [getActive]/[watchActive], which are the capture
  /// path's view and deliberately exclude archived categories. Additive
  /// member introduced by `007` — see
  /// `specs/007-account-linking-integrity/contracts/category-management-api.md`.
  Future<Result<List<Category>>> getAll();

  /// Live query of every category, active and archived, same ordering as
  /// [getAll]. History resolves expense→category display against this,
  /// not [watchActive] — a historical expense can reference an archived
  /// category and must still render its icon/name normally (US7).
  Stream<List<Category>> watchAll();

  /// Creates a new **user** category — `nameKey` is always `null`, [name]
  /// is always the literal text given. This never creates a
  /// default/translated category.
  Future<Result<Category>> create({
    required String name,
    required String color,
    required String iconName,
  });

  /// Updates an existing category. If the target is currently a default
  /// category (`isDefault: true`) and [name] is given, this performs the
  /// rename-becomes-user-category conversion documented in
  /// `docs/DATA_MODEL.md`: clears `nameKey`, sets `name`, flips
  /// `isDefault` to `false` — one write.
  Future<Result<void>> update(
    String categoryId, {
    String? name,
    String? color,
    String? iconName,
  });

  /// Rewrites `sortOrder` for every category in [orderedIds] to match the
  /// given order.
  Future<Result<void>> reorder(List<String> orderedIds);

  /// Archives (`isActive: false`) or unarchives (`isActive: true`) a
  /// category. Never touches any `expenses` document that references it.
  Future<Result<void>> setActive(String categoryId, {required bool isActive});
}
