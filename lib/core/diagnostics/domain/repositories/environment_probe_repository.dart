import 'package:wrap_my_finances/core/diagnostics/domain/entities/environment_probe.dart';
import 'package:wrap_my_finances/core/errors/result.dart';

/// Writes and reads back environment-probe documents. Implemented against
/// Firestore in `data/`; this interface stays free of Firebase imports.
abstract interface class EnvironmentProbeRepository {
  /// Writes a new probe document with the given [label] and returns it.
  Future<Result<EnvironmentProbe>> writeProbe(String label);

  /// Returns the most recently written probe in this session, if any.
  Future<Result<EnvironmentProbe?>> readLatest();
}
