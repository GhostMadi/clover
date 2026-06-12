import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final bool isExpanded;
  final bool interactive;
  final Widget? child;

  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 56.0,
    this.borderRadius = 18.0,
    this.isLoading = false,
    this.isExpanded = false,
    this.interactive = true,
    this.child,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
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

  bool get _isEnabled => (widget.interactive ? widget.onTap != null : true) && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isEnabled ? AppColors.primary : AppColors.surfaceSoft;
    final Color textColor = _isEnabled ? AppColors.textInverse : AppColors.subTextColor;

    final List<BoxShadow> shadows = _isEnabled
        ? [
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.shadowDark.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ];

    final buttonBody = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: _isEnabled ? AppColors.borderCardGreen : AppColors.border),
        boxShadow: shadows,
      ),
      child: Stack(
        children: [
          if (_isEnabled)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius - 1),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
          Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      valueColor: AlwaysStoppedAnimation(textColor),
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
        ],
      ),
    );

    final button = AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: widget.interactive ? GestureDetector(onTap: _handleTap, child: buttonBody) : buttonBody,
    );

    if (!widget.isExpanded) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}
