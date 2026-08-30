import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/platform/adaptive_widget.dart';
import 'package:flutter/material.dart';

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

/// Универсальное меню опций.
///
/// - Если передан [child], меню откроется при нажатии на него.
/// - Если [child] равен null, отобразится стандартная иконка "⋯".
/// - Если список [items] пуст, виджет ничего не рендерит.
class AppMiniMenu<T> extends AdaptiveStatelessWidget {
  const AppMiniMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.child,
    this.menuTooltip = 'Опции',
    this.iconColor,
    this.iconPadding,
  });

  final List<AppMiniMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  /// Любой виджет, который станет триггером для открытия меню (кнопка, аватар, текст и т.д.)
  final Widget? child;

  final String menuTooltip;
  final Color? iconColor;
  final EdgeInsets? iconPadding;

  @override
  Widget buildMaterial(BuildContext context, AppPalette colors) => _build(colors);

  @override
  Widget buildCupertino(BuildContext context, AppPalette colors) => _build(colors);

  Widget _build(AppPalette colors) {
    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<T>(
      tooltip: menuTooltip,
      color: colors.surface,
      menuPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border.withValues(alpha: 0.8)),
      ),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((it) {
          return PopupMenuItem<T>(
            value: it.value,
            enabled: it.enabled,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            height: 0,
            child: Row(
              children: [
                if (it.icon != null) ...[
                  Icon(it.icon, size: 20, color: it.iconColor ?? colors.textColor),
                  const SizedBox(width: 10),
                ],
                Text(
                  it.title,
                  style: AppTextStyle.base(
                    14,
                    fontWeight: FontWeight.w700,
                    color: it.titleColor ?? colors.textColor,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child:
          child ??
          Padding(
            padding: iconPadding ?? EdgeInsets.zero,
            child: Icon(
              AppIcons.moreVert.icon,
              size: 20,
              color: iconColor ?? colors.subTextColor.withValues(alpha: 0.75),
            ),
          ),
    );
  }
}
