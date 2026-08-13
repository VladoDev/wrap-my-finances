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

  @override
  String get commonUndo => 'Desfazer';

  @override
  String get historyExpenseDeletedMessage => 'Despesa excluída';

  @override
  String get historyEmptyTitle => 'Ainda não há nada aqui';

  @override
  String get historyEmptySubtitle =>
      'As despesas que você registrar vão aparecer aqui';

  @override
  String get navCaptureLabel => 'Registrar despesa';

  @override
  String get navHistoryLabel => 'Histórico';

  @override
  String wrappedGrandTotalTitle(String amount) {
    return 'Você gastou $amount este mês';
  }

  @override
  String wrappedBlackHoleTitle(String category) {
    return 'Sua categoria principal foi $category';
  }

  @override
  String wrappedHabitTitle(int count, String category) {
    return 'Você registrou $count despesas em $category';
  }

  @override
  String wrappedBiggestHitTitle(String amount) {
    return 'Sua maior despesa individual foi $amount';
  }

  @override
  String get wrappedSyncingMessage => 'Ainda sincronizando seus dados…';

  @override
  String get wrappedShareAmountsToggleLabel => 'Mostrar valores';

  @override
  String get wrappedShareButtonLabel => 'Compartilhar';

  @override
  String wrappedShareCardCountLabel(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString despesas',
      one: '$countString despesa',
    );
    return '$_temp0';
  }

  @override
  String get wrappedSuppressedCardTitle => 'Curioso sobre o mês passado?';

  @override
  String get wrappedSuppressedCardCta => 'Ver seu resumo';

  @override
  String get wrappedMonthPickerEntryLabel => 'Resumos anteriores';

  @override
  String get wrappedMonthPickerTitle => 'Escolha um mês';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAccountSection => 'Conta';

  @override
  String get settingsCategoriesSection => 'Categorias';

  @override
  String get settingsPreferencesSection => 'Preferências';

  @override
  String get settingsLinkAccountCta => 'Vincular uma conta';

  @override
  String settingsLinkedAsLabel(String provider) {
    return 'Vinculada com $provider';
  }

  @override
  String get settingsLinkGoogleOption => 'Continuar com o Google';

  @override
  String get settingsLinkAppleOption => 'Continuar com a Apple';

  @override
  String get settingsLinkUnavailableOfflineMessage =>
      'Não é possível vincular agora — você está offline';

  @override
  String get settingsLinkConflictTitle => 'Esta conta já tem dados';

  @override
  String get settingsLinkConflictBody =>
      'A conta escolhida já tem seu próprio histórico. Decida o que fazer com cada conjunto de dados.';

  @override
  String get settingsLinkConflictMergeOption => 'Combinar os dois históricos';

  @override
  String get settingsLinkConflictDiscardOption =>
      'Manter apenas o histórico desta conta';

  @override
  String get settingsLinkConflictDiscardConfirmTitle =>
      'Descartar os dados deste dispositivo?';

  @override
  String get settingsLinkConflictDiscardConfirmBody =>
      'Tudo registrado neste dispositivo será excluído permanentemente. O histórico já existente nesta conta será mantido.';

  @override
  String get settingsDeleteAccountCta => 'Excluir conta';

  @override
  String get settingsDeleteAccountConfirmTitle => 'Excluir sua conta?';

  @override
  String get settingsDeleteAccountConfirmBody =>
      'Isso exclui permanentemente sua conta e tudo o que você registrou. Isso não pode ser desfeito.';

  @override
  String get settingsDeleteAccountReauthMessage =>
      'Entre novamente para confirmar que é você';

  @override
  String get settingsCategoryCreateCta => 'Nova categoria';

  @override
  String get settingsCategoryEditorNameLabel => 'Nome';

  @override
  String get settingsCategoryArchiveCta => 'Arquivar';

  @override
  String get settingsCategoryUnarchiveCta => 'Desarquivar';

  @override
  String get settingsCategoryArchivedLabel => 'Arquivada';

  @override
  String get settingsCurrencyLabel => 'Moeda';

  @override
  String get settingsTimeZoneLabel => 'Fuso horário';
}
