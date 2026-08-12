import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';
import 'package:wrap_my_finances/core/analytics/analytics_service.dart';

/// [AnalyticsService] over [FirebaseAnalytics]. Dev-flavor events land in the
/// `dev` Firebase project, same as every other dev-flavor write (Constitution
/// Principle 6) — no separate wiring needed, `FirebaseAnalytics.instance`
/// already resolves against whichever app `Firebase.initializeApp()` set up.
@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  /// Creates the service over the injected [FirebaseAnalytics] singleton.
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  void logExpenseTimeToLog(Duration elapsed) {
    // Fire-and-forget: never awaited, never blocks the success path this
    // measurement is timing (Constitution Principle 1/2).
    unawaited(
      _analytics.logEvent(
        name: 'time_to_log_expense',
        parameters: {'duration_ms': elapsed.inMilliseconds},
      ),
    );
  }
}
