import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';

/// Settings' entry point for permanent account deletion (US6, spec.md
/// acceptance criterion 8) — a thin wrapper over [AuthRepository], kept as
/// its own use case so the call site reads the same way every other
/// Settings action does, and so future feature work (analytics, etc.) has
/// one place to hook into rather than the repository call site directly.
@injectable
class DeleteAccountUseCase {
  /// Creates the use case over [_authRepository].
  const DeleteAccountUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Deletes the current account and all of its data. [onReauthRequired]
  /// is called if a fresh sign-in is needed mid-deletion, so the UI can
  /// show `settingsDeleteAccountReauthMessage` before the native sign-in
  /// sheet reappears.
  Future<Result<void>> call({void Function()? onReauthRequired}) {
    return _authRepository.deleteAccount(onReauthRequired: onReauthRequired);
  }
}
