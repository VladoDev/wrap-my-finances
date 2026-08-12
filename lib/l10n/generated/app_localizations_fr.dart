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
}
