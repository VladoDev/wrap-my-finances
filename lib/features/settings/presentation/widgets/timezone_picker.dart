import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/settings/presentation/current_user_profile_provider.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// A curated IANA time-zone list — the same five zones
/// `DeviceLocaleTimeZoneDefaults` already establishes for this app's five
/// supported languages, never a freeform/searchable list.
const List<String> supportedTimeZones = [
  'America/New_York',
  'America/Mexico_City',
  'America/Sao_Paulo',
  'Europe/Rome',
  'Europe/Paris',
];

/// Settings' time-zone preference control (US8, FR-011): selecting a value
/// calls `UserProfileRepository.updateTimeZone` — a pure preference write
/// that never recalculates `monthKey` on any existing expense
/// (`docs/DATA_MODEL.md`, FR-011).
class TimeZonePicker extends ConsumerWidget {
  /// Creates the picker.
  const TimeZonePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(currentUserProfileProvider).valueOrNull?.timeZone;

    return DropdownButtonFormField<String>(
      initialValue: supportedTimeZones.contains(current) ? current : null,
      decoration: InputDecoration(labelText: l10n.settingsTimeZoneLabel),
      items: [
        for (final zone in supportedTimeZones)
          DropdownMenuItem(value: zone, child: Text(zone)),
      ],
      onChanged: (zone) {
        if (zone == null) return;
        unawaited(
          ref.read(userProfileRepositoryProvider).updateTimeZone(zone),
        );
      },
    );
  }
}
