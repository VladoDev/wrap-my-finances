import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/core/errors/result.dart';
import 'package:wrap_my_finances/features/auth/data/apple_sign_in_credential_provider.dart';
import 'package:wrap_my_finances/features/auth/data/google_sign_in_credential_provider.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_conflict_resolution.dart';
import 'package:wrap_my_finances/features/auth/domain/entities/link_result.dart';
import 'package:wrap_my_finances/features/auth/domain/repositories/auth_repository.dart';
import 'package:wrap_my_finances/features/categories/domain/repositories/category_repository.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';

/// [AuthRepository] over [FirebaseAuth]. `runWhenAuthenticated`'s buffering
/// is a memoized, shared [Future]: every caller that arrives before sign-in
/// resolves awaits the same in-flight sign-in attempt and each proceeds, in
/// registration order, the moment it resolves — no hand-rolled queue is
/// needed for the ordering guarantee FR-004/FR-005 ask for. See
/// `research.md`.
@LazySingleton(as: AuthRepository)
class FirebaseAuthRepository implements AuthRepository {
  /// Creates the repository over the injected [FirebaseAuth]/
  /// [FirebaseFirestore] singletons, the Google/Apple credential exchange
  /// helpers, and the [ExpenseRepository]/[CategoryRepository] domain
  /// interfaces `resolveLinkConflict`'s merge/discard paths orchestrate
  /// across (Constitution Principle 4 permits a feature depending on
  /// another feature's `domain/` repository interface — see
  /// `LogExpense` for the established precedent).
  FirebaseAuthRepository(
    this._auth,
    this._firestore,
    this._googleCredentialProvider,
    this._appleCredentialProvider,
    this._expenseRepository,
    this._categoryRepository,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignInCredentialProvider _googleCredentialProvider;
  final AppleSignInCredentialProvider _appleCredentialProvider;
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  Future<String>? _pendingSignIn;

  /// The credential that triggered the most recent `credential-already-in-
  /// use` conflict, held so `resolveLinkConflict` can complete the identity
  /// switch (`research.md` #2) without asking the caller to re-authenticate.
  AuthCredential? _pendingConflictCredential;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;

    _pendingSignIn ??= _signIn();
    try {
      return await _pendingSignIn!;
    } catch (_) {
      // Allow a later call to retry rather than permanently caching a
      // failed attempt (e.g. no connectivity at first launch).
      _pendingSignIn = null;
      rethrow;
    }
  }

  Future<String> _signIn() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  @override
  Future<T> runWhenAuthenticated<T>(
    Future<T> Function(String uid) operation,
  ) async {
    final uid = await ensureSignedIn();
    return operation(uid);
  }

  @override
  bool get isLinked => linkedProviderLabel != null;

  @override
  String? get linkedProviderLabel {
    for (final info in _auth.currentUser?.providerData ?? const <UserInfo>[]) {
      if (info.providerId == 'google.com') return 'Google';
      if (info.providerId == 'apple.com') return 'Apple';
    }
    return null;
  }

  @override
  Future<LinkResult> linkWithGoogle() =>
      _link(_googleCredentialProvider.obtainCredential, 'Google');

  @override
  Future<LinkResult> linkWithApple() =>
      _link(_appleCredentialProvider.obtainCredential, 'Apple');

  Future<LinkResult> _link(
    Future<AuthCredential> Function() obtainCredential,
    String providerLabel,
  ) async {
    final AuthCredential credential;
    try {
      credential = await obtainCredential();
    } on Object catch (error, stackTrace) {
      return LinkFailed(UnknownFailure(error, stackTrace));
    }

    try {
      await _auth.currentUser!.linkWithCredential(credential);
      return const LinkSucceeded();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _pendingConflictCredential = credential;
        return LinkConflictDetected(
          LinkConflict(existingProviderLabel: providerLabel),
        );
      }
      if (e.code == 'network-request-failed') {
        return const LinkFailed(NetworkFailure());
      }
      return LinkFailed(UnknownFailure(e, StackTrace.current));
    }
  }

  @override
  Future<Result<void>> resolveLinkConflict(
    LinkConflict conflict,
    LinkConflictResolution resolution,
  ) async {
    final credential = _pendingConflictCredential;
    if (credential == null) {
      return Failed(
        UnknownFailure(
          StateError(
            'resolveLinkConflict called with no pending conflict credential '
            '— linkWithGoogle/linkWithApple must return LinkConflictDetected '
            'first.',
          ),
          StackTrace.current,
        ),
      );
    }

    try {
      switch (resolution) {
        case LinkConflictResolution.merge:
          await _mergeIntoExistingAccount(credential);
        case LinkConflictResolution.discardLocal:
          await _discardLocalThenSwitch(credential);
      }
      _pendingConflictCredential = null;
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  /// research.md #2's exact sequence: read A's full history while still
  /// authenticated as A, switch to B, then write everything into B's
  /// collections with fresh ids. Default categories are matched onto B's
  /// own (already-seeded) defaults by `nameKey` rather than duplicated —
  /// every account gets the same fixed default set, so a match always
  /// exists; only A's genuinely user-created categories are recreated.
  Future<void> _mergeIntoExistingAccount(AuthCredential credential) async {
    final aExpenses = await _expenseRepository.watchAll().first;
    final aCategoriesResult = await _categoryRepository.getAll();
    final aCategories = aCategoriesResult.when(
      success: (value) => value,
      failed: (failure) =>
          throw StateError('Could not read local categories: $failure'),
    );

    await _auth.signInWithCredential(credential);

    await _categoryRepository.seedDefaultsIfNeeded();
    final bCategoriesResult = await _categoryRepository.getAll();
    final bCategories = bCategoriesResult.when(
      success: (value) => value,
      failed: (failure) => throw StateError(
        "Could not read the existing account's categories: $failure",
      ),
    );
    final bDefaultIdsByNameKey = <String, String>{
      for (final category in bCategories)
        if (category.isDefault && category.nameKey != null)
          category.nameKey!: category.id,
    };

    final categoryIdMap = <String, String>{};
    for (final category in aCategories) {
      final matchedDefaultId = category.isDefault
          ? bDefaultIdsByNameKey[category.nameKey]
          : null;
      if (matchedDefaultId != null) {
        categoryIdMap[category.id] = matchedDefaultId;
        continue;
      }
      if (category.isDefault) {
        // No matching default found (shouldn't happen — every account gets
        // the same fixed set). Fail loudly rather than silently dropping
        // the expenses that reference it.
        throw StateError(
          'No matching default category for nameKey ${category.nameKey}',
        );
      }

      final createResult = await _categoryRepository.create(
        name: category.name!,
        color: category.color,
        iconName: category.iconName,
      );
      await createResult.when(
        success: (newCategory) async {
          categoryIdMap[category.id] = newCategory.id;
          if (!category.isActive) {
            await _categoryRepository.setActive(
              newCategory.id,
              isActive: false,
            );
          }
        },
        failed: (failure) async =>
            throw StateError('Could not merge category: $failure'),
      );
    }

    for (final expense in aExpenses) {
      final remappedCategoryId =
          categoryIdMap[expense.categoryId] ?? expense.categoryId;
      final createResult = await _expenseRepository.create(
        Expense(
          id: '',
          amount: expense.amount,
          categoryId: remappedCategoryId,
          date: expense.date,
          createdAt: expense.createdAt,
          note: expense.note,
        ),
      );
      if (createResult case Failed(:final failure)) {
        throw StateError('Could not merge expense: $failure');
      }
    }
  }

  /// The inverse of the merge path's step 4: while still authenticated as
  /// A, hard-delete A's `expenses`/`categories` documents outright (an
  /// explicit, confirmed discard, not merely an unreachable orphan — FR-005)
  /// before switching to B. `firestore.rules` already allows an owner to
  /// delete their own documents in both subcollections.
  Future<void> _discardLocalThenSwitch(AuthCredential credential) async {
    final uid = _auth.currentUser!.uid;
    final userRef = _firestore.collection('users').doc(uid);
    await _deleteAllDocsIn(userRef.collection('expenses'));
    await _deleteAllDocsIn(userRef.collection('categories'));
    await _auth.signInWithCredential(credential);
  }

  Future<void> _deleteAllDocsIn(
    CollectionReference<Map<String, Object?>> ref,
  ) async {
    final snapshot = await ref.get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Deletes every expense/category document, the `users/{uid}` document,
  /// then the Firebase Auth user record itself, in that order — Firestore
  /// data first, since `firestore.rules`' ownership checks stop working the
  /// instant the auth record (and thus `request.auth`) is gone.
  ///
  /// **Retry-safety, not a false guarantee**: if `currentUser!.delete()`
  /// throws `requires-recent-login` and the re-prompted sign-in is
  /// cancelled or fails, the account's data is already gone but its auth
  /// record survives — deliberately, since deleting the identity before
  /// confirming reauth risks the opposite, worse failure (an orphaned
  /// identity with no way back in). This is safe to leave as a resumable
  /// state: every step here is idempotent (deleting an already-empty
  /// collection/an already-deleted document is a no-op), so simply calling
  /// [deleteAccount] again completes the job once reauth succeeds.
  @override
  Future<Result<void>> deleteAccount({
    void Function()? onReauthRequired,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return Failed(
        UnknownFailure(
          StateError('deleteAccount called with no signed-in user.'),
          StackTrace.current,
        ),
      );
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      await _deleteAllDocsIn(userRef.collection('expenses'));
      await _deleteAllDocsIn(userRef.collection('categories'));
      await userRef.delete();
      await _deleteAuthUserWithReauthRetry(user, onReauthRequired);
      return const Success(null);
    } on Object catch (error, stackTrace) {
      return Failed(UnknownFailure(error, stackTrace));
    }
  }

  Future<void> _deleteAuthUserWithReauthRetry(
    User user,
    void Function()? onReauthRequired,
  ) async {
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      onReauthRequired?.call();

      final credential = switch (linkedProviderLabel) {
        'Google' => await _googleCredentialProvider.obtainCredential(),
        'Apple' => await _appleCredentialProvider.obtainCredential(),
        _ => throw StateError(
          'requires-recent-login on an unlinked (purely anonymous) '
          'session — there is no provider to reauthenticate with.',
        ),
      };
      await user.reauthenticateWithCredential(credential);
      // Retried exactly once — a second failure propagates to the outer
      // catch rather than looping.
      await user.delete();
    }
  }
}
