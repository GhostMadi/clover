import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

/// Заголовок секции над группой тайлов в настройках.
class SettingsTileSectionTitle extends StatelessWidget {
  const SettingsTileSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
