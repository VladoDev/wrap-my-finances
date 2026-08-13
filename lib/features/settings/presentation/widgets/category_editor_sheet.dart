import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/design_system/theme/design_tokens.dart';
import 'package:wrap_my_finances/core/design_system/tokens/app_colors.dart';
import 'package:wrap_my_finances/core/design_system/widgets/app_button.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/categories/domain/entities/category.dart';
import 'package:wrap_my_finances/features/categories/presentation/category_icon_map.dart';
import 'package:wrap_my_finances/l10n/generated/app_localizations.dart';

String _colorToHex(Color color) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
  return '#${argb.substring(2).toUpperCase()}';
}

/// The name/color/icon form used for both creating a category and
/// rename/recolor/re-icon of an existing one (US7) — [category] `null`
/// means create mode. Color and icon choices are both fixed, design-token-
/// driven sets (`context.colors.categoryPalette` / `categoryIconMap`), per
/// FR-012 — never a freeform color wheel or icon search.
class CategoryEditorSheet extends ConsumerStatefulWidget {
  /// Creates the sheet. `null` [category] means create mode.
  const CategoryEditorSheet({this.category, super.key});

  /// The category being edited, or `null` to create a new one.
  final Category? category;

  @override
  ConsumerState<CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet> {
  late final TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIconName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedIconName = widget.category?.iconName ?? categoryIconMap.keys.first;
    // AppColorsExtension.light is a static const, so this is available
    // without a BuildContext — reading context.colors this early (before
    // the widget is mounted) would be unreliable.
    _selectedColor =
        widget.category?.color ??
        _colorToHex(AppColorsExtension.light.categoryPalette.first);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(spacing.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.settingsCategoryEditorNameLabel,
              ),
            ),
            SizedBox(height: spacing.spacingMd),
            Wrap(
              spacing: spacing.spacingSm,
              children: [
                for (final swatch in colors.categoryPalette)
                  _ColorSwatch(
                    color: swatch,
                    selected: _colorToHex(swatch) == _selectedColor,
                    onTap: () =>
                        setState(() => _selectedColor = _colorToHex(swatch)),
                  ),
              ],
            ),
            SizedBox(height: spacing.spacingMd),
            Wrap(
              spacing: spacing.spacingSm,
              children: [
                for (final entry in categoryIconMap.entries)
                  _IconChoice(
                    iconName: entry.key,
                    icon: entry.value,
                    selected: entry.key == _selectedIconName,
                    onTap: () => setState(() => _selectedIconName = entry.key),
                  ),
              ],
            ),
            SizedBox(height: spacing.spacingLg),
            AppButton(
              label: l10n.commonContinue,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    final repository = ref.read(categoryRepositoryProvider);
    final category = widget.category;
    if (category == null) {
      await repository.create(
        name: name,
        color: _selectedColor,
        iconName: _selectedIconName,
      );
    } else {
      await repository.update(
        category.id,
        name: name,
        color: _selectedColor,
        iconName: _selectedIconName,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: colors.onBackground, width: 3)
                : null,
          ),
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconName,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String iconName;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
            border: Border.all(
              color: selected ? colors.onBackground : colors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Icon(icon, color: colors.onBackground),
        ),
      ),
    );
  }
}
