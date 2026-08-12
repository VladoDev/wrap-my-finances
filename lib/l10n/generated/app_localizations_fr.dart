// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonDevBuild => 'VERSION DEV';

  @override
  String get categoryFood => 'Alimentation';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryShopping => 'Achats';

  @override
  String get categoryEntertainment => 'Divertissement';

  @override
  String get categoryHealth => 'Santé';

  @override
  String get categoryHousing => 'Logement';

  @override
  String get categoryOther => 'Autre';

  @override
  String get categoryPickerTitle => 'Choisissez une catégorie';

  @override
  String get expenseSaveErrorMessage => 'Impossible d\'enregistrer — réessayez';

  @override
  String get keypadAmountSemanticLabel => 'Montant';

  @override
  String get commonUndo => 'Annuler';

  @override
  String get historyExpenseDeletedMessage => 'Dépense supprimée';

  @override
  String get historyEmptyTitle => 'Rien ici pour l\'instant';

  @override
  String get historyEmptySubtitle =>
      'Les dépenses que vous enregistrez apparaîtront ici';

  @override
  String get navCaptureLabel => 'Enregistrer une dépense';

  @override
  String get navHistoryLabel => 'Historique';

  @override
  String wrappedGrandTotalTitle(String amount) {
    return 'Vous avez dépensé $amount ce mois-ci';
  }

  @override
  String wrappedBlackHoleTitle(String category) {
    return 'Votre catégorie principale était $category';
  }

  @override
  String wrappedHabitTitle(int count, String category) {
    return 'Vous avez enregistré $count dépenses dans $category';
  }

  @override
  String wrappedBiggestHitTitle(String amount) {
    return 'Votre dépense individuelle la plus élevée était $amount';
  }

  @override
  String get wrappedSyncingMessage =>
      'Synchronisation de vos données en cours…';

  @override
  String get wrappedShareAmountsToggleLabel => 'Afficher les montants';

  @override
  String get wrappedShareButtonLabel => 'Partager';

  @override
  String wrappedShareCardCountLabel(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dépenses',
      one: '$countString dépense',
    );
    return '$_temp0';
  }

  @override
  String get wrappedSuppressedCardTitle => 'Curieux du mois dernier ?';

  @override
  String get wrappedSuppressedCardCta => 'Voir votre résumé';

  @override
  String get wrappedMonthPickerEntryLabel => 'Résumés précédents';

  @override
  String get wrappedMonthPickerTitle => 'Choisissez un mois';
}
