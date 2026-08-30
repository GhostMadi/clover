import 'dart:ui';

import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_pill_button.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Пагинация маркеров на карте: назад / счётчик / вперёд.
class MapMarkersPaginationBar extends StatelessWidget {
  const MapMarkersPaginationBar({
    super.key,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalCount,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  final int rangeStart;
  final int rangeEnd;
  final int totalCount;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  static const double _figmaBarRadius = 36;
  static const double _figmaBlurSigma = 24;
  static const double _figmaShadowBlur = 24;
  static const double _figmaShadowOffsetY = 8;

  @override
  Widget build(BuildContext context) {
    final pillSize = context.heightByContext(AppFunctionalPillButton.figmaSize).clamp(48.0, 80.0);
    final barRadius = context.widthByContext(_figmaBarRadius);
    final blur = context.heightByContext(_figmaBlurSigma).clamp(8.0, 32.0);
    final counterText = totalCount == 0 ? '0 из 0' : '$rangeStart–$rangeEnd из $totalCount';

    return SizedBox(
      width: pillSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(barRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(barRadius),
              border: Border.all(color: context.colors.primary.withValues(alpha: 0.85)),
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadowDark.withValues(alpha: 0.10),
                  blurRadius: context.heightByContext(_figmaShadowBlur),
                  offset: Offset(0, context.heightByContext(_figmaShadowOffsetY)),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ArrowButton(
                    icon: AppIcons.arrowUp.icon,
                    enabled: canGoPrevious,
                    size: pillSize - 12,
                    onTap: onPrevious,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Маркеры',
                          style: AppTextStyle.base(
                            10,
                            color: context.colors.subTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: isLoading
                              ? SizedBox(
                                  key: const ValueKey('loading'),
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: context.colors.primary.withValues(alpha: 0.85),
                                  ),
                                )
                              : Text(
                                  counterText,
                                  key: ValueKey(counterText),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle.base(
                                    13,
                                    color: context.colors.textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  _ArrowButton(
                    icon: AppIcons.arrowDown.icon,
                    enabled: canGoNext,
                    size: pillSize - 12,
                    onTap: onNext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final double size;
  final VoidCallback onTap;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> with SingleTickerProviderStateMixin {
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
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    _jellyController.trigger(haptic: false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = (widget.size * 0.42).clamp(20.0, 30.0);

    return AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.32,
        child: Material(
          color: widget.enabled ? context.colors.white : context.colors.surfaceMuted,
          shape: CircleBorder(
            side: BorderSide(
              color: widget.enabled ? context.colors.primary.withValues(alpha: 0.85) : context.colors.borderSoft,
            ),
          ),
          child: InkWell(
            onTap: widget.enabled ? _handleTap : null,
            borderRadius: BorderRadius.circular(widget.size / 2),
            splashColor: context.colors.primary.withValues(alpha: 0.12),
            highlightColor: context.colors.primary.withValues(alpha: 0.06),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Icon(widget.icon, size: iconSize, color: context.colors.textColor),
            ),
          ),
        ),
      ),
    );
  }
}
