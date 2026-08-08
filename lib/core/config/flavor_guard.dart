import 'package:wrap_my_finances/core/config/app_environment.dart';

/// Describes a detected mismatch between the native build flavor and the
/// Dart [AppEnvironment] it was launched with.
class FlavorMismatch {
  /// Creates a mismatch description.
  const FlavorMismatch({
    required this.nativeFlavor,
    required this.dartEnvironment,
  });

  /// The native flavor reported by the platform (`appFlavor`), or `null`
  /// when the build was not compiled with a flavor at all.
  final String? nativeFlavor;

  /// The Dart-side [AppEnvironment.name] the app was launched with.
  final String dartEnvironment;

  /// Human-readable message naming both sides of the conflict.
  String get message =>
      'Flavor mismatch: native flavor "$nativeFlavor" vs Dart env '
      '"$dartEnvironment". You almost certainly forgot '
      '-t lib/main_$dartEnvironment.dart';
}

/// Pure comparison between the native flavor and the active [AppEnvironment].
///
/// Returns `null` when they agree, or a [FlavorMismatch] describing the
/// conflict otherwise. Kept pure (no `package:flutter/services.dart` import)
/// so it is unit-testable without a running Flutter binding — see
/// `research.md`.
FlavorMismatch? checkFlavorConsistency({
  required String? appFlavor,
  required AppEnvironment env,
}) {
  if (appFlavor == env.name) {
    return null;
  }
  return FlavorMismatch(nativeFlavor: appFlavor, dartEnvironment: env.name);
}
