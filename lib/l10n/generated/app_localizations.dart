import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// Label for a primary button that advances to the next step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Label for a button that dismisses the current action without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Label for a button that retries a failed action.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Label for a destructive button that removes an item.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Label shown on the dev-flavor ribbon banner, never present in prod builds.
  ///
  /// In en, this message translates to:
  /// **'DEV BUILD'**
  String get commonDevBuild;

  /// Default category name for food and dining expenses.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// Default category name for transportation expenses.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// Default category name for shopping expenses.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// Default category name for entertainment expenses.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// Default category name for health expenses.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// Default category name for housing expenses.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// Default category name for expenses that don't fit another category.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Heading of the bottom sheet shown after entering an amount, to pick the expense's category.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get categoryPickerTitle;

  /// Non-blocking snackbar text shown when an expense can't be written to local storage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save — try again'**
  String get expenseSaveErrorMessage;

  /// Screen-reader label for the large amount display on the capture screen.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get keypadAmountSemanticLabel;

  /// Action label for reversing the most recent action, e.g. a deleted expense.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// Snackbar text shown after swiping an expense away in the history screen.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get historyExpenseDeletedMessage;

  /// Heading shown in the history screen when no expenses have been logged.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get historyEmptyTitle;

  /// Body text shown under historyEmptyTitle in the history screen's empty state.
  ///
  /// In en, this message translates to:
  /// **'Expenses you log will show up here'**
  String get historyEmptySubtitle;

  /// Semantic/visible label for the navigation bar's capture destination.
  ///
  /// In en, this message translates to:
  /// **'Log expense'**
  String get navCaptureLabel;

  /// Semantic/visible label for the navigation bar's history destination.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistoryLabel;

  /// Wrapped story: the month's total spend. Copy carries the product's voice — flagged for native-speaker review, not machine translation.
  ///
  /// In en, this message translates to:
  /// **'You spent {amount} this month'**
  String wrappedGrandTotalTitle(String amount);

  /// Wrapped story: the month's highest-spend category. Copy carries the product's voice — flagged for native-speaker review, not machine translation.
  ///
  /// In en, this message translates to:
  /// **'Your top category was {category}'**
  String wrappedBlackHoleTitle(String category);

  /// Wrapped story: how many expenses were logged in the top category. Copy carries the product's voice — flagged for native-speaker review, not machine translation.
  ///
  /// In en, this message translates to:
  /// **'You logged {count} transactions in {category}'**
  String wrappedHabitTitle(int count, String category);

  /// Wrapped story: the single largest expense of the month. Copy carries the product's voice — flagged for native-speaker review, not machine translation.
  ///
  /// In en, this message translates to:
  /// **'Your biggest single expense was {amount}'**
  String wrappedBiggestHitTitle(String amount);

  /// Shown instead of any figure when the local cache doesn't yet match the server's document count for the month. Flagged for native-speaker review.
  ///
  /// In en, this message translates to:
  /// **'Still syncing your data…'**
  String get wrappedSyncingMessage;

  /// Label for the visible toggle that opts into including monetary figures on the shared image, off by default.
  ///
  /// In en, this message translates to:
  /// **'Show amounts'**
  String get wrappedShareAmountsToggleLabel;

  /// Label for the button that rasterizes and shares the final Wrapped card.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get wrappedShareButtonLabel;

  /// Transaction count shown on the shareable card, pluralized. Flagged for native-speaker review.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} expense} other{{count} expenses}}'**
  String wrappedShareCardCountLabel(num count);

  /// Title of the small, dismissible card offered on the history screen when the month had too few expenses to auto-trigger Wrapped. Flagged for native-speaker review.
  ///
  /// In en, this message translates to:
  /// **'Curious about last month?'**
  String get wrappedSuppressedCardTitle;

  /// Call-to-action label on the suppressed-Wrapped card.
  ///
  /// In en, this message translates to:
  /// **'See your summary'**
  String get wrappedSuppressedCardCta;

  /// Label for the button on the history screen that opens the month picker for past Wrapped summaries.
  ///
  /// In en, this message translates to:
  /// **'Past summaries'**
  String get wrappedMonthPickerEntryLabel;

  /// Heading of the bottom sheet listing past months with data, for manual Wrapped access.
  ///
  /// In en, this message translates to:
  /// **'Choose a month'**
  String get wrappedMonthPickerTitle;

  /// Title of the Settings screen and its navigation-bar destination.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Heading of the account section in Settings (linking, deletion).
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// Heading of the category management section in Settings.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategoriesSection;

  /// Heading of the currency/time-zone preferences section in Settings.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferencesSection;

  /// Call-to-action shown in Settings when the current session has not linked a Google or Apple account.
  ///
  /// In en, this message translates to:
  /// **'Link an account'**
  String get settingsLinkAccountCta;

  /// Status shown in Settings once an account is linked, naming the provider.
  ///
  /// In en, this message translates to:
  /// **'Linked via {provider}'**
  String settingsLinkedAsLabel(String provider);

  /// Option to link the current session to a Google account.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get settingsLinkGoogleOption;

  /// Option to link the current session to an Apple account.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get settingsLinkAppleOption;

  /// Shown when linking an account fails because the device has no network connection.
  ///
  /// In en, this message translates to:
  /// **'Can\'t link right now — you\'re offline'**
  String get settingsLinkUnavailableOfflineMessage;

  /// Title of the screen shown when the account being linked already has its own history.
  ///
  /// In en, this message translates to:
  /// **'This account already has data'**
  String get settingsLinkConflictTitle;

  /// Body text explaining the link conflict and that a decision is required.
  ///
  /// In en, this message translates to:
  /// **'The account you chose already has its own history. Decide what happens with each set of data.'**
  String get settingsLinkConflictBody;

  /// Option to merge the current device's anonymous history into the existing account's history.
  ///
  /// In en, this message translates to:
  /// **'Combine both histories'**
  String get settingsLinkConflictMergeOption;

  /// Option to discard the current device's anonymous history and keep only the existing account's.
  ///
  /// In en, this message translates to:
  /// **'Keep only this account\'s history'**
  String get settingsLinkConflictDiscardOption;

  /// Title of the explicit confirmation required before discarding the current device's history.
  ///
  /// In en, this message translates to:
  /// **'Discard this device\'s data?'**
  String get settingsLinkConflictDiscardConfirmTitle;

  /// Body text naming exactly what will be discarded, before the discard is confirmed.
  ///
  /// In en, this message translates to:
  /// **'Everything logged on this device will be permanently deleted. This account\'s existing history will be kept.'**
  String get settingsLinkConflictDiscardConfirmBody;

  /// Call-to-action in Settings that starts the account-deletion flow.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccountCta;

  /// Title of the explicit confirmation required before deleting the account.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get settingsDeleteAccountConfirmTitle;

  /// Body text warning that account deletion is permanent, before it is confirmed.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and everything you\'ve logged. This can\'t be undone.'**
  String get settingsDeleteAccountConfirmBody;

  /// Shown when deleting the account requires a fresh sign-in before it can proceed.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to confirm it\'s really you'**
  String get settingsDeleteAccountReauthMessage;

  /// Call-to-action that opens the category editor to create a new category.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get settingsCategoryCreateCta;

  /// Label for the category name field in the category editor.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsCategoryEditorNameLabel;

  /// Action that archives a category, hiding it from the capture picker.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get settingsCategoryArchiveCta;

  /// Action that unarchives a category, restoring it to the capture picker.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get settingsCategoryUnarchiveCta;

  /// Label marking an archived category in the management list.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get settingsCategoryArchivedLabel;

  /// Label for the currency preference control in Settings.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrencyLabel;

  /// Label for the time-zone preference control in Settings.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get settingsTimeZoneLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
