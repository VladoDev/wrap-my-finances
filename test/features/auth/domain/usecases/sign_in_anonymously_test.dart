import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/sign_in_anonymously.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test(
    'calls AuthRepository.ensureSignedIn exactly once and discards the result',
    () async {
      final repository = _MockAuthRepository();
      when(repository.ensureSignedIn).thenAnswer((_) async => 'uid_123');

      final useCase = SignInAnonymouslyUseCase(repository);
      await useCase.call();

      verify(repository.ensureSignedIn).called(1);
    },
  );
}
