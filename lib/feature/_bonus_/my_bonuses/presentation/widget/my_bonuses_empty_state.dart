import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

class MyBonusesEmptyState extends StatelessWidget {
  const MyBonusesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.serviceAccent(AppServiceKind.bonus);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: accent.soft, shape: BoxShape.circle),
              child: Icon(AppIcons.loyalty.icon, size: 34, color: accent.icon),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.bonus_my_empty_title,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(17, fontWeight: FontWeight.w700, color: context.colors.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.bonus_my_empty_subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
