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
import 'package:wrap_my_finances/core/instrumentation/app_launch_clock.dart';
import 'package:wrap_my_finances/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:wrap_my_finances/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/purge_expired_deleted_expenses.dart';
import 'package:wrap_my_finances/features/user_profile/domain/usecases/ensure_user_profile.dart';

/// Shared init for every flavor entrypoint, in order: flavor-consistency
/// guard, Firebase, Firestore offline settings, dependency injection, a
/// silent anonymous session, then `runApp`. Callers pass the flavor-specific
/// [env] and Firebase [options].
Future<void> bootstrap(
  AppEnvironment env,
  FirebaseOptions options,
) async {
  // "Process start" for FR-003/SC-001's timing budget — captured before
  // anything else runs. See specs/004-quick-expense-capture/research.md.
  getIt.registerSingleton<AppLaunchClock>(AppLaunchClock(DateTime.now()));

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

  // Also fire-and-forget, in parallel with sign-in, so default categories
  // are normally already seeded by the time the user reaches the category
  // step. Idempotent — safe on every launch. See
  // specs/004-quick-expense-capture/research.md.
  unawaited(getIt<SeedDefaultCategoriesUseCase>().call());

  // Also fire-and-forget, at every launch: hard-deletes expenses
  // soft-deleted more than 30 days ago. Idempotent, never blocks first
  // frame. See specs/005-expense-history-undo/research.md.
  unawaited(getIt<PurgeExpiredDeletedExpensesUseCase>().call());

  // Also fire-and-forget, at every launch: creates users/{uid} (timeZone +
  // wrappedLastSeenMonth) if it doesn't exist yet — no feature wrote to
  // this document before 006. Idempotent, never blocks first frame. See
  // specs/006-monthly-wrapped-summary/research.md #1.
  unawaited(getIt<EnsureUserProfileUseCase>().call());

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
