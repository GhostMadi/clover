import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';

class AppOutlinedButton extends StatefulWidget {
  const AppOutlinedButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 56.0,
    this.borderRadius = 18.0,
    this.isLoading = false,
    this.isExpanded = false,
    this.child,
    this.service,
  });

  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final bool isExpanded;
  final Widget? child;
  final AppServiceKind? service;

  @override
  State<AppOutlinedButton> createState() => _AppOutlinedButtonState();
}

class _AppOutlinedButtonState extends State<AppOutlinedButton> with SingleTickerProviderStateMixin {
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
    _jellyController.trigger();
    widget.onTap!();
  }

  bool get _isEnabled => widget.onTap != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final serviceAccent = widget.service != null ? colors.serviceAccent(widget.service!) : null;
    final backgroundColor = _isEnabled ? (serviceAccent?.soft ?? colors.surface) : colors.surfaceMuted;
    final borderColor = _isEnabled ? (serviceAccent?.icon ?? colors.borderInput) : colors.border;
    final textColor = _isEnabled ? (serviceAccent?.icon ?? colors.textColor) : colors.subTextColor;
    final loaderColor = serviceAccent?.icon ?? colors.primary;

    final button = AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: borderColor),
            boxShadow: _isEnabled
                ? [
                    BoxShadow(
                      color: colors.shadowDark.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      valueColor: AlwaysStoppedAnimation(loaderColor),
                    ),
                  )
                : widget.child ??
                      Text(
                        widget.text,
                        style: AppTextStyle.base(
                          16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),
          ),
        ),
      ),
    );

    if (!widget.isExpanded) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}
