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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsCategoriesSection => 'Categories';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsLinkAccountCta => 'Link an account';

  @override
  String settingsLinkedAsLabel(String provider) {
    return 'Linked via $provider';
  }

  @override
  String get settingsLinkGoogleOption => 'Continue with Google';

  @override
  String get settingsLinkAppleOption => 'Continue with Apple';

  @override
  String get settingsLinkUnavailableOfflineMessage =>
      'Can\'t link right now — you\'re offline';

  @override
  String get settingsLinkConflictTitle => 'This account already has data';

  @override
  String get settingsLinkConflictBody =>
      'The account you chose already has its own history. Decide what happens with each set of data.';

  @override
  String get settingsLinkConflictMergeOption => 'Combine both histories';

  @override
  String get settingsLinkConflictDiscardOption =>
      'Keep only this account\'s history';

  @override
  String get settingsLinkConflictDiscardConfirmTitle =>
      'Discard this device\'s data?';

  @override
  String get settingsLinkConflictDiscardConfirmBody =>
      'Everything logged on this device will be permanently deleted. This account\'s existing history will be kept.';

  @override
  String get settingsDeleteAccountCta => 'Delete account';

  @override
  String get settingsDeleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get settingsDeleteAccountConfirmBody =>
      'This permanently deletes your account and everything you\'ve logged. This can\'t be undone.';

  @override
  String get settingsDeleteAccountReauthMessage =>
      'Please sign in again to confirm it\'s really you';

  @override
  String get settingsCategoryCreateCta => 'New category';

  @override
  String get settingsCategoryEditorNameLabel => 'Name';

  @override
  String get settingsCategoryArchiveCta => 'Archive';

  @override
  String get settingsCategoryUnarchiveCta => 'Unarchive';

  @override
  String get settingsCategoryArchivedLabel => 'Archived';

  @override
  String get settingsCurrencyLabel => 'Currency';

  @override
  String get settingsTimeZoneLabel => 'Time zone';
}
