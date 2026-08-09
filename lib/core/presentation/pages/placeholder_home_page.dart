import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The app's single route until a real product screen exists (`004`
/// onward). Shows only the dev-flavor ribbon banner from
/// `docs/UI_UX_SPEC.md` §6 — no other content, no product functionality.
/// Not itself a product screen; see spec.md Assumptions.
class PlaceholderHomePage extends ConsumerWidget {
  /// Creates the page.
  const PlaceholderHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvironmentProvider);
    final colors = context.colors;
    final spacing = context.spacing;

    return Scaffold(
      body: SafeArea(
        child: env.showDebugBanner
            ? Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(spacing.spacingMd),
                  child: Container(
                    key: const Key('debug-banner'),
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.spacingMd,
                      vertical: spacing.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.danger,
                      borderRadius: BorderRadius.circular(spacing.radiusSm),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.commonDevBuild,
                      style: context.typography.bodySmall.copyWith(
                        color: colors.onDanger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
