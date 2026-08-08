import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

/// Registers the Firebase SDK singletons for `@injectable` constructor
/// injection. `Firebase.initializeApp()` must already have completed by the
/// time these are read — `bootstrap()` guarantees that ordering.
@module
abstract class FirebaseModule {
  /// The default Firestore instance for the active Firebase app.
  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// The default FirebaseAuth instance for the active Firebase app.
  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;
}
