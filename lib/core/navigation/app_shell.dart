import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The floating nav bar from `docs/UI_UX_SPEC.md` §4: "detached from the
/// bottom edge so it reads as a floating pill." Overlaid via `Stack`/
/// `Align`, not `Scaffold.bottomNavigationBar` (a docked slot, which
/// couldn't render "floating" — see
/// `specs/005-expense-history-undo/research.md`). `child` is whichever
/// route `go_router`'s `ShellRoute` is currently showing; each route keeps
/// owning its own `Scaffold` unchanged.
class AppShell extends StatelessWidget {
  /// Creates the shell around [child], highlighting [currentLocation].
  const AppShell({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  /// The active route's content.
  final Widget child;

  /// The router's current location (e.g. `/` or `/history`), used only to
  /// highlight the matching nav item — never to decide what to render.
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: spacing.spacingMd),
                child: Material(
                  color: colors.surface,
                  elevation: 4,
                  shape: spacing.radiusPill,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.spacingLg,
                      vertical: spacing.spacingSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NavItem(
                          icon: Icons.dialpad,
                          label: l10n.navCaptureLabel,
                          selected: currentLocation == '/',
                          onTap: () => context.go('/'),
                        ),
                        SizedBox(width: spacing.spacingLg),
                        _NavItem(
                          icon: Icons.history,
                          label: l10n.navHistoryLabel,
                          selected: currentLocation == '/history',
                          onTap: () => context.go('/history'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.spacingSm,
            vertical: context.spacing.spacingXs,
          ),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}
