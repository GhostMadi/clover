import 'dart:ui';

import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Панель функциональных кнопок для отображения внизу экрана.
class AppFunctionalButtons extends StatefulWidget {
  const AppFunctionalButtons({
    required this.buttons,
    this.collapsed = false,
    this.backgroundColor,
    super.key,
  });

  final List<FunctionalButtonItem> buttons;
  final bool collapsed;
  final Color? backgroundColor;

  /// Ширина сжатой панели на одну кнопку (px из Figma).
  static const double figmaCollapsedBarWidthPerButton = 130;

  static List<FunctionalButtonItem> visibleButtons(List<FunctionalButtonItem> buttons, bool collapsed) {
    if (!collapsed) {
      return buttons;
    }

    return buttons.where((button) => button.keepWhenCollapsed).toList();
  }

  static int visibleButtonCount(List<FunctionalButtonItem> buttons, bool collapsed) {
    return visibleButtons(buttons, collapsed).length;
  }

  /// Горизонтальный inset для центрирования сжатой панели. `0` — полная ширина.
  static double collapsedHorizontalInset(
    BuildContext context, {
    required List<FunctionalButtonItem> buttons,
    required bool collapsed,
    double? figmaCollapsedWidthPerButton,
  }) {
    if (!collapsed) {
      return 0;
    }

    final visibleCount = visibleButtonCount(buttons, collapsed);
    if (visibleCount == 0) {
      return 0;
    }

    final perButton = figmaCollapsedWidthPerButton ?? figmaCollapsedBarWidthPerButton;
    final barWidth = context.widthByContext(perButton) * visibleCount;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return ((screenWidth - barWidth) / 2).clamp(0.0, double.infinity);
  }

  @override
  State<AppFunctionalButtons> createState() => _AppFunctionalButtonsState();
}

class _AppFunctionalButtonsState extends State<AppFunctionalButtons> {
  // Константы геометрии полностью скопированы
  // из AppNavBar для идентичного визуала
  static const double _figmaBarRadius = 36;
  static const double _figmaBarHeight = 64;
  static const double _figmaBlurSigma = 24;
  static const double _figmaShadowBlur = 24;
  static const double _figmaShadowOffsetY = 8;
  static const double _figmaIndicatorRadius = 28;
  static const double _figmaIconSize = 24;
  static const double _figmaLabelFont = 11;
  static const double _figmaLabelGap = 4;

  static const Duration _animationDuration = Duration(milliseconds: 280);
  static const Curve _animationCurve = Curves.easeOutBack;

  @override
  Widget build(BuildContext context) {
    if (widget.buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    final barRadius = context.widthByContext(_figmaBarRadius);
    final height = context.heightByContext(_figmaBarHeight);
    final blur = context.heightByContext(_figmaBlurSigma).clamp(8.0, 32.0);

    final visibleButtons = AppFunctionalButtons.visibleButtons(widget.buttons, widget.collapsed);

    if (visibleButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(barRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.surfaceSoft.withValues(alpha: 0.92),
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
          child: AnimatedSize(
            duration: _animationDuration,
            curve: _animationCurve,
            alignment: Alignment.center,
            child: SizedBox(
              height: height.clamp(40.0, 120.0),
              child: ClipRect(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(visibleButtons.length, (index) {
                    final button = visibleButtons[index];

                    return Expanded(
                      child: AnimatedPadding(
                        duration: _animationDuration,
                        curve: _animationCurve,
                        padding: EdgeInsets.all(button.customColor != null ? 2 : 6),
                        child: _FunctionalButtonTab(
                          button: button,
                          indicatorRadius: context.widthByContext(_figmaIndicatorRadius),
                          iconSize: context.heightByContext(_figmaIconSize),
                          labelFontSize: context.heightByContext(_figmaLabelFont),
                          labelGap: context.heightByContext(_figmaLabelGap),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FunctionalButtonTab extends StatefulWidget {
  const _FunctionalButtonTab({
    required this.button,
    required this.indicatorRadius,
    required this.iconSize,
    required this.labelFontSize,
    required this.labelGap,
  });

  final FunctionalButtonItem button;
  final double indicatorRadius;
  final double iconSize;
  final double labelFontSize;
  final double labelGap;

  @override
  State<_FunctionalButtonTab> createState() => _FunctionalButtonTabState();
}

class _FunctionalButtonTabState extends State<_FunctionalButtonTab> with SingleTickerProviderStateMixin {
  late final JellyPressController _jellyController;

  @override
  void initState() {
    super.initState();

    _jellyController = JellyPressController(
      vsync: this,
      onAnimationSwap: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _jellyController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.button.isLoading) return;

    HapticFeedback.lightImpact();

    _jellyController.trigger(haptic: false);

    widget.button.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCustomColor = widget.button.customColor != null;

    final Color contentColor = hasCustomColor ? AppColors.textInverse : AppColors.textColor;

    return AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: Theme(
        data: Theme.of(context).copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Material(
          color: widget.button.customColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(widget.indicatorRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.button.isLoading ? null : _handleTap,
            borderRadius: BorderRadius.circular(widget.indicatorRadius),
            splashColor: (widget.button.customColor ?? AppColors.primary).withValues(alpha: 0.12),
            highlightColor: (widget.button.customColor ?? AppColors.primary).withValues(alpha: 0.06),
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.button.isLoading)
                      SizedBox(
                        height: widget.iconSize.clamp(18.0, 32.0),
                        width: widget.iconSize.clamp(18.0, 32.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(
                            widget.button.iconColor ?? contentColor,
                          ),
                        ),
                      )
                    else
                      Icon(
                        widget.button.icon,
                        size: widget.iconSize.clamp(18.0, 32.0),
                        color: widget.button.iconColor ?? contentColor,
                      ),

                    if (widget.button.label != null && !widget.button.isLoading) ...[
                      SizedBox(height: widget.labelGap),

                      Text(
                        widget.button.label!,
                        style: AppTextStyle.base(
                          widget.labelFontSize.clamp(9.0, 14.0),
                          color: widget.button.textColor ?? contentColor,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
