import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';

/// Bootstrap's only touchpoint with the `auth` feature: fire-and-forget,
/// never awaited, never blocks first frame (Constitution Principles 1/2).
@injectable
class SignInAnonymouslyUseCase {
  /// Creates the use case over [_authRepository].
  const SignInAnonymouslyUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Triggers (or confirms) an anonymous session. The result is discarded —
  /// callers that need the UID use [AuthRepository.runWhenAuthenticated].
  Future<void> call() async {
    await _authRepository.ensureSignedIn();
  }
}
