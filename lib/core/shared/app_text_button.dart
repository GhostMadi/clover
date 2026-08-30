import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';

/// Текстовая кнопка без фона — для AppBar, ссылок и вторичных действий.
class AppTextButton extends StatefulWidget {
  const AppTextButton({
    super.key,
    required this.text,
    required this.onTap,
    this.fontSize = 16,
    this.isLoading = false,
    this.padding,
    this.child,
  });

  final String text;
  final VoidCallback? onTap;
  final double fontSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  @override
  State<AppTextButton> createState() => _AppTextButtonState();
}

class _AppTextButtonState extends State<AppTextButton> with SingleTickerProviderStateMixin {
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
    if (widget.onTap == null || widget.isLoading) return;
    _jellyController.trigger(haptic: false);
    widget.onTap!();
  }

  bool get _isEnabled => widget.onTap != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = _isEnabled ? colors.primary : colors.iconMuted;

    final content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(textColor),
            ),
          )
        : widget.child ??
              Text(
                widget.text,
                style: AppTextStyle.base(
                  widget.fontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.3,
                ),
              );

    return AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isEnabled ? _handleTap : null,
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(child: content),
        ),
      ),
    );
  }
}
