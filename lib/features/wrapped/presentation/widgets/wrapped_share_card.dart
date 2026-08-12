import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_name_resolver.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/presentation/money_format.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

/// The pixel ratio the shareable card is rasterized at
/// (`docs/UI_UX_SPEC.md` §3: "Rendered from a `RepaintBoundary` at 3×
/// pixel ratio").
const double wrappedShareCardPixelRatio = 3;

/// Wrapped story 5 — "The Shareable Card" (`docs/UI_UX_SPEC.md` §3): a
/// `RepaintBoundary`-rasterized, `share_plus`-shared image. Defaults to no
/// monetary figures (FR-014); a visible toggle opts into showing the total
/// (FR-015).
class WrappedShareCard extends StatefulWidget {
  /// Creates the share card for [monthKey].
  const WrappedShareCard({
    required this.monthKey,
    required this.topCategoryId,
    required this.topCategory,
    required this.topCategoryExpenseCount,
    required this.total,
    this.shareImageBytes,
    super.key,
  });

  /// `"YYYY-MM"`.
  final String monthKey;

  /// The top category's id, per `WrappedSummary.topCategoryId`.
  final String? topCategoryId;

  /// The resolved category, if found.
  final Category? topCategory;

  /// `WrappedSummary.topCategoryExpenseCount`.
  final int topCategoryExpenseCount;

  /// The month's total — only ever rendered/shared when the amounts toggle
  /// is active.
  final Money total;

  /// Overridable share sink, so tests can intercept the rasterized PNG
  /// bytes without a platform channel. Defaults to invoking `share_plus`.
  final Future<void> Function(Uint8List pngBytes)? shareImageBytes;

  @override
  State<WrappedShareCard> createState() => _WrappedShareCardState();
}

class _WrappedShareCardState extends State<WrappedShareCard> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _showAmounts = false;

  Future<void> _share() async {
    final renderObject = _boundaryKey.currentContext!.findRenderObject();
    final boundary = renderObject! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: wrappedShareCardPixelRatio,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    if (widget.shareImageBytes != null) {
      await widget.shareImageBytes!(bytes);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'wrapped-${widget.monthKey}.png',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A bounded width — AspectRatio needs a finite constraint on at
          // least one axis, and an unbounded Column would otherwise let it
          // grow to an unreasonable height.
          SizedBox(
            width: 280,
            child: RepaintBoundary(
              key: _boundaryKey,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: _ShareCardContent(
                  monthKey: widget.monthKey,
                  topCategoryId: widget.topCategoryId,
                  topCategory: widget.topCategory,
                  topCategoryExpenseCount: widget.topCategoryExpenseCount,
                  total: widget.total,
                  showAmounts: _showAmounts,
                ),
              ),
            ),
          ),
          SwitchListTile(
            value: _showAmounts,
            onChanged: (value) => setState(() => _showAmounts = value),
            title: Text(l10n.wrappedShareAmountsToggleLabel),
          ),
          SizedBox(height: spacing.spacingSm),
          AppButton(label: l10n.wrappedShareButtonLabel, onPressed: _share),
        ],
      ),
    );
  }
}

class _ShareCardContent extends StatelessWidget {
  const _ShareCardContent({
    required this.monthKey,
    required this.topCategoryId,
    required this.topCategory,
    required this.topCategoryExpenseCount,
    required this.total,
    required this.showAmounts,
  });

  final String monthKey;
  final String? topCategoryId;
  final Category? topCategory;
  final int topCategoryExpenseCount;
  final Money total;
  final bool showAmounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final colors = context.colors;
    final spacing = context.spacing;
    final categoryLabel = topCategory == null
        ? (topCategoryId ?? '')
        : resolveCategoryName(context, topCategory!);
    final monthLabel = _formatMonth(monthKey, locale);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(spacing.radiusLg),
        border: Border.all(color: colors.outline, width: 3),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthLabel,
              style: context.typography.bodyMedium.copyWith(
                color: colors.onPrimary,
              ),
            ),
            SizedBox(height: spacing.spacingMd),
            Text(
              categoryLabel,
              style: context.typography.displayLarge.copyWith(
                color: colors.onPrimary,
              ),
            ),
            SizedBox(height: spacing.spacingSm),
            Text(
              l10n.wrappedShareCardCountLabel(topCategoryExpenseCount),
              style: context.typography.titleMedium.copyWith(
                color: colors.onPrimary,
              ),
            ),
            if (showAmounts) ...[
              SizedBox(height: spacing.spacingMd),
              Text(
                formatMinorUnits(total.minorUnits, locale),
                style: context.typography.titleMedium.copyWith(
                  color: colors.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMonth(String monthKey, String locale) {
    final parts = monthKey.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat.yMMMM(locale).format(date);
  }
}
