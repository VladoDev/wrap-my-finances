import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/wrapped/presentation/widgets/wrapped_progress_bar.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required int sceneCount,
    required int activeIndex,
    Duration duration = const Duration(seconds: 1),
    bool isPaused = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WrappedProgressBar(
            sceneCount: sceneCount,
            activeIndex: activeIndex,
            duration: duration,
            isPaused: isPaused,
          ),
        ),
      ),
    );
  }

  testWidgets('renders one segment per scene', (tester) async {
    await pump(tester, sceneCount: 5, activeIndex: 0);

    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
  });

  testWidgets('segments before the active one are fully filled', (
    tester,
  ) async {
    await pump(tester, sceneCount: 4, activeIndex: 2);
    await tester.pump(const Duration(milliseconds: 1));

    final indicators = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();

    expect(indicators[0].value, 1);
    expect(indicators[1].value, 1);
  });

  testWidgets('scenes after the active one are empty', (tester) async {
    await pump(tester, sceneCount: 4, activeIndex: 1);
    await tester.pump(const Duration(milliseconds: 1));

    final indicators = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();

    expect(indicators[2].value, 0);
    expect(indicators[3].value, 0);
  });

  testWidgets('the active segment fills over duration', (tester) async {
    await pump(
      tester,
      sceneCount: 3,
      activeIndex: 0,
      duration: const Duration(milliseconds: 100),
    );

    await tester.pump(const Duration(milliseconds: 50));
    final halfway = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .first
        .value;
    expect(halfway, greaterThan(0));
    expect(halfway, lessThan(1));

    await tester.pump(const Duration(milliseconds: 60));
    final finished = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .first
        .value;
    expect(finished, 1);
  });

  testWidgets('restarts the active segment fill when activeIndex changes', (
    tester,
  ) async {
    await pump(
      tester,
      sceneCount: 3,
      activeIndex: 0,
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump(const Duration(milliseconds: 80));

    await pump(
      tester,
      sceneCount: 3,
      activeIndex: 1,
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump(const Duration(milliseconds: 1));

    final indicators = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();
    expect(indicators[0].value, 1); // now-past scene, fully filled
    expect(indicators[1].value, lessThan(0.2)); // just restarted
  });

  testWidgets('paused stops the active segment from filling further', (
    tester,
  ) async {
    await pump(
      tester,
      sceneCount: 2,
      activeIndex: 0,
      duration: const Duration(milliseconds: 100),
      isPaused: true,
    );

    await tester.pump(const Duration(milliseconds: 150));

    final value = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .first
        .value;
    expect(value, 0);
  });
}
