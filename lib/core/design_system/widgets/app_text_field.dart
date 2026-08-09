import 'package:flutter/material.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';

/// A rounded, bordered text input. [label] is always shown as a floating
/// label; [hint] and [errorText] use `bodySmall`, per `data-model.md`.
class AppTextField extends StatelessWidget {
  /// Creates a text field. [label]/[hint]/[errorText] must already be
  /// localized by the caller.
  const AppTextField({
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    super.key,
  });

  /// The floating label text.
  final String label;

  /// Optional placeholder text, shown when empty and unfocused.
  final String? hint;

  /// Optional validation error text; non-null renders the error state.
  final String? errorText;

  /// Optional controller for the underlying [TextFormField].
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(spacing.radiusSm),
      borderSide: BorderSide(color: colors.outline),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: TextFormField(
        controller: controller,
        style: typography.bodyMedium.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          labelStyle: typography.bodyMedium.copyWith(color: colors.onSurface),
          hintStyle: typography.bodySmall.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
          errorStyle: typography.bodySmall.copyWith(color: colors.danger),
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.spacingMd,
            vertical: spacing.spacingSm,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
