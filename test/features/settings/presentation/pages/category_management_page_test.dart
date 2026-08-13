import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wrap_my_finances/core/design_system/theme/app_theme.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:wrap_my_finances/features/categories/data/repositories/category_repository_impl.dart';
import 'package:wrap_my_finances/features/settings/presentation/pages/category_management_page.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

void main() {
  Future<CategoryRepositoryImpl> pump(WidgetTester tester) async {
    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final categoryRepository = CategoryRepositoryImpl(
      CategoryRemoteDataSource(firestore),
      auth,
    );
    await categoryRepository.seedDefaultsIfNeeded();
    final all = (await categoryRepository.getAll()).when(
      success: (value) => value,
      failed: (failure) => throw StateError('setup failed: $failure'),
    );
    final food = all.firstWhere((c) => c.nameKey == 'category_food');
    await categoryRepository.setActive(food.id, isActive: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CategoryManagementPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return categoryRepository;
  }

  testWidgets(
    'lists active and archived categories, visually distinguishing '
    'archived ones',
    (tester) async {
      await pump(tester);

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      // The archived category shows the "Archived" label; the others don't.
      expect(find.text('Archived'), findsOneWidget);
      final archivedRow = find.ancestor(
        of: find.text('Archived'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(of: archivedRow, matching: find.text('Food')),
        findsOneWidget,
      );
    },
  );

  testWidgets('tapping the archive/unarchive action toggles isActive', (
    tester,
  ) async {
    final repository = await pump(tester);

    // Transport is active — its row's trailing action archives it.
    final transportRow = find.ancestor(
      of: find.text('Transport'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(
        of: transportRow,
        matching: find.byIcon(Icons.archive_outlined),
      ),
    );
    await tester.pumpAndSettle();

    final all = (await repository.getAll()).when(
      success: (value) => value,
      failed: (failure) => throw StateError('assert failed: $failure'),
    );
    final transport = all.firstWhere((c) => c.nameKey == 'category_transport');
    expect(transport.isActive, isFalse);
  });
}
