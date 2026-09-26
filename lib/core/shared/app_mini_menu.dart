import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/platform/adaptive_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppMiniMenuItem<T> {
  const AppMiniMenuItem({
    required this.value,
    required this.title,
    this.icon,
    this.titleColor,
    this.iconColor,
    this.enabled = true,
  });

  final T value;
  final String title;
  final IconData? icon;
  final Color? titleColor;
  final Color? iconColor;
  final bool enabled;
}

/// Универсальное меню опций: тап по триггеру открывает [AppBottomSheet].
///
/// - Если передан [child], он станет триггером.
/// - Если [child] равен null, отобразится стандартная иконка "⋯".
/// - Если список [items] пуст, виджет ничего не рендерит.
class AppMiniMenu<T> extends AdaptiveStatelessWidget {
  const AppMiniMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.child,
    this.menuTooltip,
    this.iconColor,
    this.iconPadding,
  });

  final List<AppMiniMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  /// Любой виджет, который станет триггером для открытия меню.
  final Widget? child;

  final String? menuTooltip;
  final Color? iconColor;
  final EdgeInsets? iconPadding;

  @override
  Widget buildMaterial(BuildContext context, AppPalette colors) => _build(context, colors);

  @override
  Widget buildCupertino(BuildContext context, AppPalette colors) => _build(context, colors);

  Widget _build(BuildContext context, AppPalette colors) {
    if (items.isEmpty) return const SizedBox.shrink();

    final label = menuTooltip ?? context.l10n.common_options;
    final trigger =
        child ??
        Padding(
          padding: iconPadding ?? EdgeInsets.zero,
          child: Icon(
            AppIcons.moreVert.icon,
            size: 20,
            color: iconColor ?? colors.subTextColor.withValues(alpha: 0.75),
          ),
        );

    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openSheet(context, title: label),
        child: trigger,
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, {required String title}) async {
    HapticFeedback.selectionClick();
    final selected = await AppBottomSheet.show<T>(
      context: context,
      title: title,
      upperCaseTitle: false,
      showCloseButton: true,
      contentBottomSpacing: 8,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: context.colors.divider.withValues(alpha: 0.7),
              ),
            _AppMiniMenuSheetRow<T>(item: items[i]),
          ],
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    onSelected(selected);
  }
}

class _AppMiniMenuSheetRow<T> extends StatelessWidget {
  const _AppMiniMenuSheetRow({required this.item});

  final AppMiniMenuItem<T> item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = item.enabled;
    final titleColor = !enabled
        ? colors.subTextColor
        : (item.titleColor ?? colors.textColor);
    final iconColor = !enabled
        ? colors.subTextColor
        : (item.iconColor ?? item.titleColor ?? colors.textColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => Navigator.of(context).pop(item.value) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 22, color: iconColor),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item.title,
                  style: AppTextStyle.base(
                    15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
