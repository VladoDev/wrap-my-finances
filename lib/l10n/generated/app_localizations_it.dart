// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get commonContinue => 'Continua';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonDevBuild => 'VERSIONE DEV';

  @override
  String get categoryFood => 'Cibo';

  @override
  String get categoryTransport => 'Trasporti';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryEntertainment => 'Intrattenimento';

  @override
  String get categoryHealth => 'Salute';

  @override
  String get categoryHousing => 'Casa';

  @override
  String get categoryOther => 'Altro';

  @override
  String get categoryPickerTitle => 'Scegli una categoria';

  @override
  String get expenseSaveErrorMessage => 'Impossibile salvare — riprova';

  @override
  String get keypadAmountSemanticLabel => 'Importo';

  @override
  String get commonUndo => 'Annulla';

  @override
  String get historyExpenseDeletedMessage => 'Spesa eliminata';

  @override
  String get historyEmptyTitle => 'Non c\'è ancora nulla qui';

  @override
  String get historyEmptySubtitle => 'Le spese che registri appariranno qui';

  @override
  String get navCaptureLabel => 'Registra spesa';

  @override
  String get navHistoryLabel => 'Cronologia';

  @override
  String wrappedGrandTotalTitle(String amount) {
    return 'Hai speso $amount questo mese';
  }

  @override
  String wrappedBlackHoleTitle(String category) {
    return 'La tua categoria principale è stata $category';
  }

  @override
  String wrappedHabitTitle(int count, String category) {
    return 'Hai registrato $count spese in $category';
  }

  @override
  String wrappedBiggestHitTitle(String amount) {
    return 'La tua spesa singola più alta è stata $amount';
  }

  @override
  String get wrappedSyncingMessage => 'Sincronizzazione dei dati in corso…';

  @override
  String get wrappedShareAmountsToggleLabel => 'Mostra importi';

  @override
  String get wrappedShareButtonLabel => 'Condividi';

  @override
  String wrappedShareCardCountLabel(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString spese',
      one: '$countString spesa',
    );
    return '$_temp0';
  }

  @override
  String get wrappedSuppressedCardTitle => 'Curioso del mese scorso?';

  @override
  String get wrappedSuppressedCardCta => 'Guarda il tuo riepilogo';

  @override
  String get wrappedMonthPickerEntryLabel => 'Riepiloghi passati';

  @override
  String get wrappedMonthPickerTitle => 'Scegli un mese';
}
