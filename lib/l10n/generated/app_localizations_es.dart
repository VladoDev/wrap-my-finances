// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonDevBuild => 'VERSIÓN DEV';

  @override
  String get categoryFood => 'Comida';

  @override
  String get categoryTransport => 'Transporte';

  @override
  String get categoryShopping => 'Compras';

  @override
  String get categoryEntertainment => 'Entretenimiento';

  @override
  String get categoryHealth => 'Salud';

  @override
  String get categoryHousing => 'Vivienda';

  @override
  String get categoryOther => 'Otro';

  @override
  String get categoryPickerTitle => 'Elige una categoría';

  @override
  String get expenseSaveErrorMessage =>
      'No se pudo guardar — inténtalo de nuevo';

  @override
  String get keypadAmountSemanticLabel => 'Monto';

  @override
  String get commonUndo => 'Deshacer';

  @override
  String get historyExpenseDeletedMessage => 'Gasto eliminado';

  @override
  String get historyEmptyTitle => 'Todavía no hay nada aquí';

  @override
  String get historyEmptySubtitle => 'Los gastos que registres aparecerán aquí';

  @override
  String get navCaptureLabel => 'Registrar gasto';

  @override
  String get navHistoryLabel => 'Historial';
}
