import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

/// Общая surface-карточка для секций отметок / зарплаты.
class AttendanceSettingsSurface extends StatelessWidget {
  const AttendanceSettingsSurface({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                title!,
                style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w700),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
