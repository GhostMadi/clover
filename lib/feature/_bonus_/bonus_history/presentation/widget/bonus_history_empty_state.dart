import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

class BonusHistoryEmptyState extends StatelessWidget {
  const BonusHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.sizeOf(context).height * 0.15),
      child: Text(
        'История пока пуста',
        textAlign: TextAlign.center,
        style: AppTextStyle.base(15, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
