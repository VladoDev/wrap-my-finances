// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDevBuild => 'DEV BUILD';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryPickerTitle => 'Choose a category';

  @override
  String get expenseSaveErrorMessage => 'Couldn\'t save — try again';

  @override
  String get keypadAmountSemanticLabel => 'Amount';

  @override
  String get commonUndo => 'Undo';

  @override
  String get historyExpenseDeletedMessage => 'Expense deleted';

  @override
  String get historyEmptyTitle => 'Nothing here yet';

  @override
  String get historyEmptySubtitle => 'Expenses you log will show up here';

  @override
  String get navCaptureLabel => 'Log expense';

  @override
  String get navHistoryLabel => 'History';

  @override
  String wrappedGrandTotalTitle(String amount) {
    return 'You spent $amount this month';
  }

  @override
  String wrappedBlackHoleTitle(String category) {
    return 'Your top category was $category';
  }

  @override
  String wrappedHabitTitle(int count, String category) {
    return 'You logged $count transactions in $category';
  }

  @override
  String wrappedBiggestHitTitle(String amount) {
    return 'Your biggest single expense was $amount';
  }

  @override
  String get wrappedSyncingMessage => 'Still syncing your data…';

  @override
  String get wrappedShareAmountsToggleLabel => 'Show amounts';

  @override
  String get wrappedShareButtonLabel => 'Share';

  @override
  String wrappedShareCardCountLabel(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString expenses',
      one: '$countString expense',
    );
    return '$_temp0';
  }

  @override
  String get wrappedSuppressedCardTitle => 'Curious about last month?';

  @override
  String get wrappedSuppressedCardCta => 'See your summary';

  @override
  String get wrappedMonthPickerEntryLabel => 'Past summaries';

  @override
  String get wrappedMonthPickerTitle => 'Choose a month';
}
