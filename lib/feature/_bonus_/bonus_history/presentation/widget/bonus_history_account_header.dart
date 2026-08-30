import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:clover/feature/_bonus_/shared/data/bonus_format.dart';
import 'package:flutter/material.dart';

class BonusHistoryAccountHeader extends StatelessWidget {
  const BonusHistoryAccountHeader({super.key, required this.account});

  final BonusAccountItem account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.hostDisplayName,
                  style: AppTextStyle.base(16, fontWeight: FontWeight.w700, color: context.colors.textColor),
                ),
                if (account.usernameLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    account.usernameLabel,
                    style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                account.formattedBalance,
                style: AppTextStyle.base(22, fontWeight: FontWeight.w800, color: context.colors.primary),
              ),
              Text(
                BonusFormat.bonusWord(account.balance),
                style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
