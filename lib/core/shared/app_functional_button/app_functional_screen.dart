import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_buttons.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:flutter/material.dart';

class AppFunctionalScreen extends StatefulWidget {
  const AppFunctionalScreen({
    required this.body,
    required this.buttons,
    this.backgroundColor,
    this.collapsed = false,
    this.collapsedBarWidthPerButton,
    super.key,
  });

  final Widget body;
  final List<FunctionalButtonItem> buttons;
  final Color? backgroundColor;

  /// Когда `true`, панель сжимается и скрывает кнопки без [FunctionalButtonItem.keepWhenCollapsed].
  final bool collapsed;

  /// Ширина сжатой панели на одну кнопку (px из Figma). По умолчанию — 130.
  final double? collapsedBarWidthPerButton;

  static const double _figmaBarHeight = 64;
  static const double _figmaFloatingBottom = 16;
  static const double _figmaFloatingHorizontal = 24;

  /// Отступы для левитирующей панели на экране.
  static EdgeInsets floatingInsets(BuildContext context) {
    return EdgeInsets.fromLTRB(
      context.widthByContext(_figmaFloatingHorizontal),
      0,
      context.widthByContext(_figmaFloatingHorizontal),
      context.heightByContext(_figmaFloatingBottom) + MediaQuery.paddingOf(context).bottom,
    );
  }

  /// Нижний отступ для внутренностей скролла, чтобы контент не перекрывался панелью.
  static double scrollBottomClearance(BuildContext context) {
    final insets = floatingInsets(context);
    return insets.bottom + context.heightByContext(_figmaBarHeight);
  }

  @override
  State<AppFunctionalScreen> createState() => _AppFunctionalScreenState();
}

class _AppFunctionalScreenState extends State<AppFunctionalScreen> {
  static const Duration _animationDuration = Duration(milliseconds: 280);
  static const Curve _animationCurve = Curves.easeOutBack;

  @override
  Widget build(BuildContext context) {
    final horizontalInset = AppFunctionalButtons.collapsedHorizontalInset(
      context,
      buttons: widget.buttons,
      collapsed: widget.collapsed,
      figmaCollapsedWidthPerButton: widget.collapsedBarWidthPerButton,
    );

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? AppColors.pageBackground,
      body: Stack(
        children: [
          Positioned.fill(child: widget.body),
          if (widget.buttons.isNotEmpty)
            AnimatedPositioned(
              duration: _animationDuration,
              curve: _animationCurve,
              left: horizontalInset,
              right: horizontalInset,
              bottom: 0,
              child: AnimatedPadding(
                duration: _animationDuration,
                curve: _animationCurve,
                padding: AppFunctionalScreen.floatingInsets(context),
                child: AppFunctionalButtons(
                  buttons: widget.buttons,
                  collapsed: widget.collapsed,
                  backgroundColor: widget.backgroundColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
