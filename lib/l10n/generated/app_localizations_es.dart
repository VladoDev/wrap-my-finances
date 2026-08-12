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

  @override
  String wrappedGrandTotalTitle(String amount) {
    return 'Gastaste $amount este mes';
  }

  @override
  String wrappedBlackHoleTitle(String category) {
    return 'Tu categoría principal fue $category';
  }

  @override
  String wrappedHabitTitle(int count, String category) {
    return 'Registraste $count gastos en $category';
  }

  @override
  String wrappedBiggestHitTitle(String amount) {
    return 'Tu gasto individual más alto fue $amount';
  }

  @override
  String get wrappedSyncingMessage => 'Todavía sincronizando tus datos…';

  @override
  String get wrappedShareAmountsToggleLabel => 'Mostrar montos';

  @override
  String get wrappedShareButtonLabel => 'Compartir';

  @override
  String wrappedShareCardCountLabel(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString gastos',
      one: '$countString gasto',
    );
    return '$_temp0';
  }

  @override
  String get wrappedSuppressedCardTitle => '¿Curiosidad por el mes pasado?';

  @override
  String get wrappedSuppressedCardCta => 'Ver tu resumen';

  @override
  String get wrappedMonthPickerEntryLabel => 'Resúmenes anteriores';

  @override
  String get wrappedMonthPickerTitle => 'Elige un mes';
}
