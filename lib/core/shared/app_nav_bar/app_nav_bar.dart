import 'dart:ui';

import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar_item.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const _animationDuration = Duration(milliseconds: 320);
  static const _animationCurve = Curves.easeOutCubic;

  /// Длительность/кривая анимации layout дашборда (accessory + сдвиг навбара).
  static const dashboardLayoutDuration = _animationDuration;
  static const dashboardLayoutCurve = _animationCurve;

  static const double _figmaIndicatorInset = 4;
  static const double _figmaBarRadius = 36;
  static const double _figmaIndicatorRadius = 28;
  static const double _figmaBarHeight = 64;
  static const double _figmaBlurSigma = 24;
  static const double _figmaShadowBlur = 24;
  static const double _figmaShadowOffsetY = 8;
  static const double _figmaIndicatorShadowBlur = 8;
  static const double _figmaIndicatorShadowOffsetY = 2;
  static const double _figmaIconSize = 24;
  static const double _figmaLabelFont = 11;
  static const double _figmaLabelGap = 4;
  static const double _figmaFloatingBottom = 16;
  static const double _figmaFloatingHorizontal = 80;

  /// Отступы для плавающего навбара на [AppDashboardPage].
  static EdgeInsets dashboardFloatingInsets(BuildContext context) {
    return EdgeInsets.fromLTRB(
      context.widthByContext(_figmaFloatingHorizontal),
      0,
      context.widthByContext(_figmaFloatingHorizontal),
      context.heightByContext(_figmaFloatingBottom) + MediaQuery.paddingOf(context).bottom,
    );
  }

  /// Нижний отступ в скролле, чтобы последний контент не уходил под навбар.
  static double scrollBottomClearance(BuildContext context) {
    final insets = dashboardFloatingInsets(context);
    return insets.bottom + context.heightByContext(_figmaBarHeight);
  }

  /// Ширина навбара на дашборде без боковых accessory-кнопок.
  static double dashboardPreferredWidth(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    return screenW - context.widthByContext(_figmaFloatingHorizontal) * 2;
  }

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty);
    assert(currentIndex < items.length);

    final barRadius = context.widthByContext(_figmaBarRadius);
    final indicatorRadius = context.widthByContext(_figmaIndicatorRadius);
    final inset = context.widthByContext(_figmaIndicatorInset);
    final height = context.heightByContext(_figmaBarHeight) - inset * 2;
    final blur = context.heightByContext(_figmaBlurSigma).clamp(8.0, 32.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(barRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surfaceSoft.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(barRadius),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.10),
                blurRadius: context.heightByContext(_figmaShadowBlur),
                offset: Offset(0, context.heightByContext(_figmaShadowOffsetY)),
              ),
            ],
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.all(inset),
            child: SizedBox(
              height: height.clamp(40.0, 120.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / items.length;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: _animationDuration,
                        curve: _animationCurve,
                        left: tabWidth * currentIndex,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(indicatorRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: context.heightByContext(_figmaIndicatorShadowBlur),
                                  offset: Offset(0, context.heightByContext(_figmaIndicatorShadowOffsetY)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Row(
                        children: List.generate(items.length, (index) {
                          return Expanded(
                            child: _AppNavBarTab(
                              item: items[index],
                              isSelected: index == currentIndex,
                              indicatorRadius: indicatorRadius,
                              iconSize: context.heightByContext(_figmaIconSize),
                              labelFontSize: context.heightByContext(_figmaLabelFont),
                              labelGap: context.heightByContext(_figmaLabelGap),
                              onTap: () {
                                if (index != currentIndex) {
                                  HapticFeedback.selectionClick();
                                }
                                onTap(index);
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppNavBarTab extends StatefulWidget {
  const _AppNavBarTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.indicatorRadius,
    required this.iconSize,
    required this.labelFontSize,
    required this.labelGap,
  });

  final AppNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final double indicatorRadius;
  final double iconSize;
  final double labelFontSize;
  final double labelGap;

  @override
  State<_AppNavBarTab> createState() => _AppNavBarTabState();
}

class _AppNavBarTabState extends State<_AppNavBarTab> with SingleTickerProviderStateMixin {
  late final JellyPressController _jellyController;

  @override
  void initState() {
    super.initState();
    _jellyController = JellyPressController(
      vsync: this,
      onAnimationSwap: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _jellyController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _jellyController.trigger(haptic: false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isSelected ? AppColors.textInverse : AppColors.iconMuted;

    return AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(widget.indicatorRadius),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                size: widget.iconSize.clamp(18.0, 32.0),
                color: iconColor,
              ),

              if (widget.item.label != null) ...[
                SizedBox(height: widget.labelGap),
                AnimatedDefaultTextStyle(
                  duration: AppNavBar._animationDuration,
                  style: AppTextStyle.base(
                    widget.labelFontSize.clamp(9.0, 14.0),
                    color: iconColor,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.0,
                  ),
                  child: Text(widget.item.label!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
