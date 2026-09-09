import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Плавающий bubble-навбар дашборда со скользящим индикатором выбранной вкладки.
///
/// Позицию (лево / центр / право) задаёт родитель через [AnimatedPositioned].
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.backgroundColor,
    this.padding,
    super.key,
  }) : assert(currentIndex >= 0);

  final int currentIndex;
  final List<AppNavBarItem> items;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  static const _animationDuration = Duration(milliseconds: 420);
  static const _animationCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  static const dashboardLayoutDuration = _animationDuration;
  static const dashboardLayoutCurve = _animationCurve;

  static const double _figmaBarHeight = 64;
  static const double _figmaIconSize = 24;
  static const double _figmaLabelFont = 11;
  static const double _figmaLabelGap = 4;
  static const double _figmaFloatingBottom = 18;
  static const double _figmaFloatingHorizontal = 72;
  static const double _innerPadding = 4;

  static EdgeInsets dashboardFloatingInsets(BuildContext context) {
    return EdgeInsets.fromLTRB(
      context.widthByContext(_figmaFloatingHorizontal),
      0,
      context.widthByContext(_figmaFloatingHorizontal),
      context.heightByContext(_figmaFloatingBottom) +
          MediaQuery.paddingOf(context).bottom,
    );
  }

  static double scrollBottomClearance(BuildContext context) {
    final insets = dashboardFloatingInsets(context);
    return insets.bottom + context.heightByContext(_figmaBarHeight);
  }

  static double dashboardPreferredWidth(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return screenW - context.widthByContext(_figmaFloatingHorizontal) * 2;
  }

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty);
    assert(currentIndex < items.length);

    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;
    final barHeight =
        context.heightByContext(_figmaBarHeight).clamp(48.0, 80.0);
    final iconSize =
        context.heightByContext(_figmaIconSize).clamp(18.0, 32.0);
    final labelFont =
        context.heightByContext(_figmaLabelFont).clamp(9.0, 14.0);
    final labelGap = context.heightByContext(_figmaLabelGap);
    final radius = barHeight / 2;
    final index = currentIndex.clamp(0, items.length - 1);

    final inactive = isDark ? colors.iconMuted : colors.black.withValues(alpha: 0.72);
    final active = colors.primary;
    final track = backgroundColor ??
        (isDark ? colors.surfaceMuted : colors.surfaceMuted.withValues(alpha: 0.96));

    final bar = Material(
      color: track,
      elevation: 10,
      shadowColor: colors.shadowDark.withValues(alpha: isDark ? 0.45 : 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      // Без ink-слоя: иначе при тапе мигает квадратный splash поверх bubble.
      type: MaterialType.canvas,
      child: SizedBox(
        height: barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final innerW = constraints.maxWidth - _innerPadding * 2;
            final tabW = innerW / items.length;
            final indicatorRadius = (barHeight - _innerPadding * 2) / 2;

            return Padding(
              padding: const EdgeInsets.all(_innerPadding),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedPositioned(
                    duration: _animationDuration,
                    curve: _animationCurve,
                    left: index * tabW,
                    width: tabW,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: isDark ? colors.surfaceSoft : colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(indicatorRadius),
                        ),
                        shadows: [
                          BoxShadow(
                            color: colors.shadowDark.withValues(
                              alpha: isDark ? 0.35 : 0.1,
                            ),
                            blurRadius: isDark ? 6 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavTab(
                            item: items[i],
                            selected: i == index,
                            activeColor: active,
                            inactiveColor: inactive,
                            iconSize: iconSize,
                            labelFont: labelFont,
                            labelGap: labelGap,
                            onTap: () {
                              if (i != index) {
                                HapticFeedback.selectionClick();
                              }
                              onTap(i);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (padding == null) return bar;
    return Padding(padding: padding!, child: bar);
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.iconSize,
    required this.labelFont,
    required this.labelGap,
    required this.onTap,
  });

  final AppNavBarItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final double iconSize;
  final double labelFont;
  final double labelGap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    final label = item.label;
    final behind = item.behindIcon;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (behind == null)
            _TabIconWithBadge(
              showBadge: item.showBadge,
              child: Icon(item.icon, size: iconSize, color: color),
            )
          else
            _StackedNavIcon(
              front: item.icon,
              behind: behind,
              size: iconSize,
              color: color,
              selected: selected,
            ),
          if (label != null && label.isNotEmpty) ...[
            SizedBox(height: labelGap),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.base(
                labelFont,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabIconWithBadge extends StatelessWidget {
  const _TabIconWithBadge({required this.showBadge, required this.child});

  final bool showBadge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.colors.destructive,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.surface, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Основная иконка + явный badge второго экрана в правом верхнем углу.
class _StackedNavIcon extends StatelessWidget {
  const _StackedNavIcon({
    required this.front,
    required this.behind,
    required this.size,
    required this.color,
    required this.selected,
  });

  final IconData front;
  final IconData behind;
  final double size;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;

    final badgeSize = (size * 0.78).clamp(14.0, 20.0);
    final badgeIconSize = badgeSize * 0.62;
    final box = size + badgeSize * 0.42;

    final badgeBg = selected
        ? colors.primary
        : (isDark ? colors.surfaceSoft : colors.white);
    final badgeFg = selected ? colors.white : color.withValues(alpha: 0.9);
    final badgeBorder =
        selected ? colors.pageBackground : color.withValues(alpha: 0.28);

    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(front, size: size, color: color),
          ),
          Positioned(
            right: -2,
            top: -3,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: badgeBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowDark.withValues(alpha: 0.16),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(behind, size: badgeIconSize, color: badgeFg),
            ),
          ),
        ],
      ),
    );
  }
}
