// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonDevBuild => 'VERSÃO DEV';

  @override
  String get categoryFood => 'Alimentação';

  @override
  String get categoryTransport => 'Transporte';

  @override
  String get categoryShopping => 'Compras';

  @override
  String get categoryEntertainment => 'Entretenimento';

  @override
  String get categoryHealth => 'Saúde';

  @override
  String get categoryHousing => 'Moradia';

  @override
  String get categoryOther => 'Outro';

  @override
  String get categoryPickerTitle => 'Escolha uma categoria';

  @override
  String get expenseSaveErrorMessage =>
      'Não foi possível salvar — tente novamente';

  @override
  String get keypadAmountSemanticLabel => 'Valor';
}
