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
  });

  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final bool isExpanded;

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
    final Color backgroundColor = _isEnabled ? AppColors.surface : AppColors.surfaceMuted;
    final Color borderColor = _isEnabled ? AppColors.borderInput : AppColors.border;
    final Color textColor = _isEnabled ? AppColors.textColor : AppColors.subTextColor;

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
                      color: AppColors.shadowDark.withValues(alpha: 0.05),
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
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  )
                : Text(
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
