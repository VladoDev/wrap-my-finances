import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/features/settings/presentation/widgets/currency_picker.dart';
import 'package:wrap_my_finances/features/settings/presentation/widgets/settings_account_section.dart';
import 'package:wrap_my_finances/features/settings/presentation/widgets/timezone_picker.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The app's first Settings screen (`docs/ROADMAP.md` Phase 3): three
/// sections — Account (linking/deletion), Categories (management), and
/// Preferences (currency/time zone). This shell assembles the section
/// layout; each section's real content is wired in by its own story
/// (`US1`/`US6` for Account, `US7` for Categories, `US8` for Preferences).
class SettingsPage extends StatelessWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.spacingLg),
          children: [
            Text(
              l10n.settingsTitle,
              style: context.typography.displayLarge.copyWith(
                color: colors.onBackground,
              ),
            ),
            SizedBox(height: spacing.spacingLg),
            _SettingsSection(
              title: l10n.settingsAccountSection,
              child: const SettingsAccountSection(),
            ),
            _SettingsSection(
              title: l10n.settingsCategoriesSection,
              child: AppButton(
                label: l10n.settingsCategoriesSection,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push('/settings/categories'),
              ),
            ),
            _SettingsSection(
              title: l10n.settingsPreferencesSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CurrencyPicker(),
                  SizedBox(height: spacing.spacingMd),
                  const TimeZonePicker(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.typography.titleMedium.copyWith(
              color: context.colors.onBackground,
            ),
          ),
          SizedBox(height: spacing.spacingSm),
          child,
        ],
      ),
    );
  }
}
