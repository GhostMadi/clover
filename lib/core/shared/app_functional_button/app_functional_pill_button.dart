import 'dart:ui';

import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Одна плавающая кнопка в стиле [AppFunctionalButtons] / [AppNavBar].
class AppFunctionalPillButton extends StatefulWidget {
  const AppFunctionalPillButton({
    required this.icon,
    required this.onTap,
    this.customColor,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.isLoading = false,
    this.showBadge = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? customColor;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isLoading;
  final bool showBadge;

  static const double _figmaSize = 64;
  static const double figmaSize = _figmaSize;
  static const double _figmaBarRadius = 100; // капсула — как у AppNavBar
  static const double _figmaBlurSigma = 20;
  static const double _figmaShadowBlur = 20;
  static const double _figmaShadowOffsetY = 8;
  static const double _figmaIconSize = 24;

  @override
  State<AppFunctionalPillButton> createState() => _AppFunctionalPillButtonState();
}

class _AppFunctionalPillButtonState extends State<AppFunctionalPillButton> with SingleTickerProviderStateMixin {
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
    if (widget.isLoading) return;
    HapticFeedback.lightImpact();
    _jellyController.trigger(haptic: false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = context.heightByContext(AppFunctionalPillButton._figmaSize).clamp(48.0, 80.0);
    final barRadius = context.widthByContext(AppFunctionalPillButton._figmaBarRadius);
    final blur = context.heightByContext(AppFunctionalPillButton._figmaBlurSigma).clamp(8.0, 32.0);
    final iconSize = context.heightByContext(AppFunctionalPillButton._figmaIconSize).clamp(18.0, 32.0);
    final hasCustomColor = widget.customColor != null;
    final contentColor = hasCustomColor ? colors.textInverse : colors.textColor;
    final backgroundColor = widget.backgroundColor ?? colors.surfaceSoft;
    final borderColor = widget.borderColor ?? colors.border;

    return AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(barRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: backgroundColor.withValues(alpha: hasCustomColor ? 0.88 : 0.72),
                    borderRadius: BorderRadius.circular(barRadius),
                    border: Border.all(color: borderColor.withValues(alpha: 0.45)),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowDark.withValues(alpha: 0.06),
                        blurRadius: context.heightByContext(AppFunctionalPillButton._figmaShadowBlur),
                        offset: Offset(0, context.heightByContext(AppFunctionalPillButton._figmaShadowOffsetY)),
                      ),
                      BoxShadow(
                        color: colors.shadowDark.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: widget.customColor ?? Colors.transparent,
                    borderRadius: BorderRadius.circular(barRadius),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: widget.isLoading ? null : _handleTap,
                      borderRadius: BorderRadius.circular(barRadius),
                      splashColor: (widget.customColor ?? colors.primary).withValues(alpha: 0.12),
                      highlightColor: (widget.customColor ?? colors.primary).withValues(alpha: 0.06),
                      child: Center(
                        child: widget.isLoading
                            ? SizedBox(
                                width: iconSize,
                                height: iconSize,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation(widget.iconColor ?? contentColor),
                                ),
                              )
                            : Icon(
                                widget.icon,
                                size: iconSize,
                                color: widget.iconColor ?? contentColor,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showBadge)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surfaceSoft, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
