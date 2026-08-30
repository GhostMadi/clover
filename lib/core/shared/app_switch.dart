import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

/// Переключатель в стиле приложения.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canChange = enabled && onChanged != null;

    return Switch.adaptive(
      value: value,
      onChanged: canChange ? onChanged : null,
      activeThumbColor: colors.textInverse,
      activeTrackColor: colors.primary,
      inactiveThumbColor: colors.white,
      inactiveTrackColor: colors.border,
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.primary;
        return colors.borderSoft;
      }),
    );
  }
}

/// Строка с заголовком и [AppSwitch] — для настроек и шторок.
class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: hasSubtitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.base(
                      15,
                      color: enabled ? colors.textColor : colors.subTextColor,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!.trim(),
                      style: AppTextStyle.base(
                        13,
                        color: colors.subTextColor,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppSwitch(value: value, onChanged: onChanged, enabled: enabled),
          ],
        ),
      ),
    );
  }
}
