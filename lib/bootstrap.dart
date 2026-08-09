import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wrap_my_finances/app.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/config/flavor_guard.dart';
import 'package:wrap_my_finances/core/di/injection.dart';

/// Shared init for every flavor entrypoint, in order: flavor-consistency
/// guard, Firebase, Firestore offline settings, a silent anonymous session,
/// dependency injection, then `runApp`. Callers pass the flavor-specific
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

  // Fire-and-forget: never blocks first frame. Writes that need a session
  // (e.g. the environment probe) await FirebaseAuth.instance.currentUser
  // themselves — see FirestoreEnvironmentProbeRepository. See research.md.
  unawaited(FirebaseAuth.instance.signInAnonymously());

  await configureDependencies(env);

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
