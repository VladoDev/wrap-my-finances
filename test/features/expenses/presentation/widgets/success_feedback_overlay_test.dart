import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/features/expenses/presentation/widgets/success_feedback_overlay.dart';

void main() {
  testWidgets('renders a checkmark and calls onCompleted once', (
    tester,
  ) async {
    var completedCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SuccessFeedbackOverlay(
            onCompleted: () => completedCount++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pumpAndSettle();
    expect(completedCount, 1);
  });

  testWidgets('collapses to a cross-fade under reduce motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SuccessFeedbackOverlay(onCompleted: () {}),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(SuccessFeedbackOverlay),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SuccessFeedbackOverlay),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });
}
