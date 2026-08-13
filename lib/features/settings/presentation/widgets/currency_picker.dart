import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/settings/presentation/current_user_profile_provider.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// A curated, fixed list of ISO 4217 codes — matching the scope
/// `DeviceLocaleDefaults` already establishes for this app's five
/// supported languages, never a freeform/searchable currency list.
const List<String> supportedCurrencyCodes = ['USD', 'MXN', 'BRL', 'EUR'];

/// Settings' currency preference control (US8, FR-011): selecting a value
/// calls `UserProfileRepository.updateCurrencyCode` — a pure preference
/// write that never touches any existing expense (FR-013).
class CurrencyPicker extends ConsumerWidget {
  /// Creates the picker.
  const CurrencyPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref
        .watch(currentUserProfileProvider)
        .valueOrNull
        ?.currencyCode;

    return DropdownButtonFormField<String>(
      initialValue: supportedCurrencyCodes.contains(current) ? current : null,
      decoration: InputDecoration(labelText: l10n.settingsCurrencyLabel),
      items: [
        for (final code in supportedCurrencyCodes)
          DropdownMenuItem(value: code, child: Text(code)),
      ],
      onChanged: (code) {
        if (code == null) return;
        unawaited(
          ref.read(userProfileRepositoryProvider).updateCurrencyCode(code),
        );
      },
    );
  }
}
