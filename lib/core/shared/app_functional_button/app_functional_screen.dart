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

  /// Ширина сжатой панели на одну кнопку (px из Figma), если кнопок ≥ 2.
  /// Одна кнопка (обычно «Назад») — квадратная пилюля [_figmaBarHeight], не полоса на всю ширину.
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

  double? _collapsedBarWidth(BuildContext context) {
    if (!widget.collapsed) return null;

    final visibleCount = AppFunctionalButtons.visibleButtonCount(
      widget.buttons,
      widget.collapsed,
    );
    if (visibleCount == 0) return null;

    // Одна кнопка → квадрат по высоте бара (как AppFunctionalPillButton).
    final perButtonFigma = visibleCount == 1
        ? AppFunctionalScreen._figmaBarHeight
        : (widget.collapsedBarWidthPerButton ??
            AppFunctionalButtons.figmaCollapsedBarWidthPerButton);

    return visibleCount == 1
        ? context.heightByContext(perButtonFigma).clamp(48.0, 80.0)
        : context.widthByContext(perButtonFigma) * visibleCount;
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = _collapsedBarWidth(context);

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? context.colors.pageBackground,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: widget.body),
          if (widget.buttons.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedPadding(
                duration: _animationDuration,
                curve: _animationCurve,
                padding: AppFunctionalScreen.floatingInsets(context),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedSize(
                    duration: _animationDuration,
                    curve: _animationCurve,
                    child: barWidth == null
                        ? AppFunctionalButtons(
                            buttons: widget.buttons,
                            collapsed: widget.collapsed,
                            backgroundColor: widget.backgroundColor,
                          )
                        : SizedBox(
                            width: barWidth,
                            child: AppFunctionalButtons(
                              buttons: widget.buttons,
                              collapsed: widget.collapsed,
                              backgroundColor: widget.backgroundColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
