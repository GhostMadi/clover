import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';

/// Компактная кнопка фильтра рядом с табами профиля.
class ProfileFilterButton extends StatelessWidget {
  const ProfileFilterButton({
    super.key,
    required this.activeCount,
    required this.onTap,
    this.isLoading = false,
  });

  final int activeCount;
  final VoidCallback? onTap;
  final bool isLoading;

  static const double size = 44;

  bool get _isActive => activeCount > 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _isActive ? context.colors.successSoft.withValues(alpha: 0.65) : context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isActive
                  ? context.colors.primary.withValues(alpha: 0.45)
                  : context.colors.border.withValues(alpha: 0.55),
            ),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 22,
                color: _isActive ? context.colors.primary : context.colors.iconMuted,
              ),
              if (_isActive)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
