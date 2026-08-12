import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';

/// Seeds the default category set on app start. Called fire-and-forget from
/// `bootstrap()`, alongside sign-in — never awaited, never blocks first
/// frame. Idempotent, so calling it on every launch is safe. See
/// `specs/004-quick-expense-capture/contracts/expense-capture-api.md`.
@injectable
class SeedDefaultCategoriesUseCase {
  /// Creates the use case.
  SeedDefaultCategoriesUseCase(this._authRepository, this._categoryRepository);

  final AuthRepository _authRepository;
  final CategoryRepository _categoryRepository;

  /// Runs the seed, deferring until sign-in resolves if it hasn't yet.
  Future<void> call() {
    return _authRepository.runWhenAuthenticated(
      (uid) => _categoryRepository.seedDefaultsIfNeeded(),
    );
  }
}
