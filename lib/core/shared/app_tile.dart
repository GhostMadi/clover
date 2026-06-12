import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

/// Строка списка / настройки в стиле приложения.
///
/// Размеры — px из Figma, масштабируются через [ContextExtension].
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.destructive = false,
    this.filled = false,
    this.showDivider = false,
    this.borderRadius = 5,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;
  final bool destructive;
  final bool filled;
  final bool showDivider;

  /// px Figma; по умолчанию 18 для [filled], иначе без скругления контейнера.
  final double? borderRadius;

  static const double _figmaMinHeight = 56;
  static const double _figmaHPadding = 16;
  static const double _figmaVPadding = 12;
  static const double _figmaGap = 12;
  static const double _figmaTitleFont = 15;
  static const double _figmaSubtitleFont = 12;
  static const double _figmaGapTitleSubtitle = 2;
  static const double _figmaIconSize = 22;
  static const double _figmaLeadingSize = 40;
  static const double _figmaLeadingRadius = 12;
  static const double _figmaChevronSize = 20;
  static const double _figmaRadius = 18;
  static const double _figmaBorderWidth = 0.85;
  static const double _figmaDividerIndent = 68;

  bool get _isInteractive => enabled && onTap != null;

  @override
  Widget build(BuildContext context) {
    final minHeight = context.heightByContext(_figmaMinHeight);
    final hPadding = context.widthByContext(_figmaHPadding);
    final vPadding = context.heightByContext(_figmaVPadding);
    final gap = context.widthByContext(_figmaGap);
    final titleFont = context.heightByContext(_figmaTitleFont);
    final subtitleFont = context.heightByContext(_figmaSubtitleFont);
    final radiusValue = borderRadius ?? (filled ? _figmaRadius : 0);
    final radius = context.widthByContext(radiusValue);

    final titleColor = !enabled
        ? AppColors.subTextColor
        : destructive
        ? AppColors.destructive
        : selected
        ? AppColors.primary
        : AppColors.textColor;

    final subtitleColor = AppColors.subTextColor.withValues(alpha: enabled ? 0.88 : 0.55);

    final leadingWidget = leading ?? _buildLeading(context);
    final trailingWidget = trailing ?? (showChevron ? _buildChevron(context) : null);

    final tileBody = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: filled
          ? BoxDecoration(
              color: selected ? AppColors.successSoft.withValues(alpha: 0.5) : AppColors.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.38)
                    : AppColors.border.withValues(alpha: 0.55),
                width: context.widthByContext(_figmaBorderWidth),
              ),
            )
          : selected
          ? BoxDecoration(
              color: AppColors.successSoft.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(radius),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingWidget != null) ...[leadingWidget, SizedBox(width: gap)],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(
                    titleFont,
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (_hasSubtitle) ...[
                  SizedBox(height: context.heightByContext(_figmaGapTitleSubtitle)),
                  Text(
                    subtitle!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.base(
                      subtitleFont,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingWidget != null) ...[SizedBox(width: gap), trailingWidget],
        ],
      ),
    );

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isInteractive ? onTap : null,
        borderRadius: radiusValue > 0 ? BorderRadius.circular(radius) : null,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: tileBody,
      ),
    );

    if (!showDivider) return tile;

    final dividerIndent = leadingWidget != null ? context.widthByContext(_figmaDividerIndent) : hPadding;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        Divider(
          height: 1,
          thickness: 1,
          indent: dividerIndent,
          endIndent: hPadding,
          color: AppColors.divider,
        ),
      ],
    );
  }

  bool get _hasSubtitle {
    final text = subtitle?.trim();
    return text != null && text.isNotEmpty;
  }

  Widget? _buildLeading(BuildContext context) {
    if (icon == null) return null;

    final size = context.heightByContext(_figmaLeadingSize);
    final iconSize = context.heightByContext(_figmaIconSize);
    final leadingRadius = context.widthByContext(_figmaLeadingRadius);

    final fg = iconColor ?? (selected ? AppColors.primary : AppColors.textColor);
    final bg =
        iconBackgroundColor ?? (selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceSoft);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(leadingRadius)),
      child: Icon(icon, size: iconSize, color: enabled ? fg : AppColors.iconMuted),
    );
  }

  Widget _buildChevron(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: context.heightByContext(_figmaChevronSize),
      color: enabled ? AppColors.iconMuted : AppColors.border,
    );
  }
}

/// Группа [AppTile] с общей обводкой и скруглением.
class AppTileGroup extends StatelessWidget {
  const AppTileGroup({super.key, required this.children, this.borderRadius});

  final List<Widget> children;
  final double? borderRadius;

  static const double _figmaRadius = 18;
  static const double _figmaBorderWidth = 0.85;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final radius = context.widthByContext(borderRadius ?? _figmaRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.55),
          width: context.widthByContext(_figmaBorderWidth),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++)
              i == children.length - 1 ? children[i] : _withDivider(children[i]),
          ],
        ),
      ),
    );
  }

  static Widget _withDivider(Widget child) {
    if (child is AppTile && child.showDivider) return child;
    return AppTileDividerWrapper(child: child);
  }
}

class AppTileDividerWrapper extends StatelessWidget {
  const AppTileDividerWrapper({super.key, required this.child});

  final Widget child;

  static const double _figmaHPadding = 16;
  static const double _figmaDividerIndent = 68;

  @override
  Widget build(BuildContext context) {
    final hPadding = context.widthByContext(_figmaHPadding);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        Divider(
          height: 1,
          thickness: 1,
          indent: context.widthByContext(_figmaDividerIndent),
          endIndent: hPadding,
          color: AppColors.divider,
        ),
      ],
    );
  }
}
