import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wrap_my_finances/app.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/config/flavor_guard.dart';
import 'package:wrap_my_finances/core/di/injection.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/sign_in_anonymously.dart';

/// Shared init for every flavor entrypoint, in order: flavor-consistency
/// guard, Firebase, Firestore offline settings, dependency injection, a
/// silent anonymous session, then `runApp`. Callers pass the flavor-specific
/// [env] and Firebase [options].
Future<void> bootstrap(
  AppEnvironment env,
  FirebaseOptions options,
) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nunito ships bundled under assets/fonts/ (see pubspec.yaml); this stops
  // google_fonts from ever attempting a network fetch, so first frame never
  // waits on one. See research.md.
  GoogleFonts.config.allowRuntimeFetching = false;

  final mismatch = checkFlavorConsistency(appFlavor: appFlavor, env: env);
  if (mismatch != null) {
    throw StateError(mismatch.message);
  }

  await Firebase.initializeApp(options: options);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await configureDependencies(env);

  // Fire-and-forget: never blocks first frame. Writes that need a session
  // call AuthRepository.runWhenAuthenticated themselves, which buffers
  // until sign-in resolves — see features/auth and research.md.
  unawaited(getIt<SignInAnonymouslyUseCase>().call());

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
