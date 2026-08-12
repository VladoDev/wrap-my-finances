import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/user_profile/domain/repositories/user_profile_repository.dart';

/// Creates `users/{uid}` if it doesn't exist yet. Called fire-and-forget
/// from `bootstrap()`, alongside sign-in, category seeding, and the
/// 30-day purge — never awaited, never blocks first frame. Idempotent, so
/// running it on every launch is safe. See
/// `specs/006-monthly-wrapped-summary/contracts/wrapped-domain-api.md`.
@injectable
class EnsureUserProfileUseCase {
  /// Creates the use case.
  EnsureUserProfileUseCase(this._authRepository, this._userProfileRepository);

  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

  /// Runs the check, deferring until sign-in resolves if it hasn't yet.
  Future<void> call() {
    return _authRepository.runWhenAuthenticated(
      (_) => _userProfileRepository.ensureExists(),
    );
  }
}
