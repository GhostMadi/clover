import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';

/// Компактная кнопка фильтра рядом с табами профиля (акцент «Ресурсы»).
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
    final accent = context.colors.serviceAccent(kResourcesService);

    return Material(
      color: accent.soft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.ctaBorder),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2, color: accent.icon),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      AppIcons.tune.icon,
                      size: 22,
                      color: accent.icon,
                    ),
                    if (_isActive)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent.icon,
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
