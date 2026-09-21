import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

class BonusHistoryEmptyState extends StatelessWidget {
  const BonusHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.sizeOf(context).height * 0.08),
      child: Column(
        children: [
          Icon(AppIcons.accessTime.icon, size: 40, color: context.colors.iconMuted),
          const SizedBox(height: 12),
          Text(
            'История пока пуста',
            textAlign: TextAlign.center,
            style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Начисления и списания появятся после завершённых визитов',
            textAlign: TextAlign.center,
            style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
          ),
        ],
      ),
    );
  }
}
