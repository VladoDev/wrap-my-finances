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
}
