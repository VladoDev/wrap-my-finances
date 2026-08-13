import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict_resolution.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_result.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';

/// Which identity provider the user chose from the Settings link CTA.
enum LinkProvider {
  /// Google, via `google_sign_in`.
  google,

  /// Apple, via `sign_in_with_apple` — offered wherever Google is, per
  /// Apple App Store Review Guideline 4.8.
  apple,
}

/// Settings' entry point for account linking.
///
/// US3's conflict routing stays out of this class (a domain-layer use case
/// cannot depend on `go_router`/`BuildContext`, per Constitution Principle
/// 4 — see `SettingsAccountSection._link`). What *does* belong here is US2:
/// when a conflict is detected but the local, still-anonymous session has
/// no real history to lose (the "fresh install" case), there is nothing
/// for the user to decide — this resolves it as `discardLocal`
/// automatically rather than interrupting them with a conflict prompt for
/// data they don't have.
@injectable
class LinkAccountUseCase {
  /// Creates the use case over [_authRepository] and the repositories used
  /// to detect an empty local session.
  const LinkAccountUseCase(
    this._authRepository,
    this._expenseRepository,
    this._categoryRepository,
  );

  final AuthRepository _authRepository;
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  /// Attempts to link the current session to [provider].
  Future<LinkResult> call(LinkProvider provider) async {
    final result = await switch (provider) {
      LinkProvider.google => _authRepository.linkWithGoogle(),
      LinkProvider.apple => _authRepository.linkWithApple(),
    };

    if (result is! LinkConflictDetected || !await _hasNoLocalHistory()) {
      return result;
    }

    final resolved = await _authRepository.resolveLinkConflict(
      result.conflict,
      LinkConflictResolution.discardLocal,
    );
    return resolved.when(
      success: (_) => const LinkSucceeded(),
      failed: LinkFailed.new,
    );
  }

  /// Whether the local, still-anonymous session has no expenses and no
  /// user-created categories — only the always-reseeded defaults, if any.
  /// A read failure is treated as "cannot confirm empty", never as empty:
  /// silently discarding real data on an ambiguous read is worse than
  /// falling back to asking the user explicitly (US3's conflict prompt).
  Future<bool> _hasNoLocalHistory() async {
    final expenses = await _expenseRepository.watchAll().first;
    if (expenses.isNotEmpty) return false;

    final categoriesResult = await _categoryRepository.getAll();
    return categoriesResult.when(
      success: (categories) => categories.every((c) => c.isDefault),
      failed: (_) => false,
    );
  }
}
