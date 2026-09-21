import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:clover/feature/_bonus_/shared/data/bonus_format.dart';
import 'package:flutter/material.dart';

/// Шапка деталки: баланс крупно, мастер вторично.
class BonusHistoryAccountHeader extends StatelessWidget {
  const BonusHistoryAccountHeader({super.key, required this.account});

  final BonusAccountItem account;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.serviceAccent(AppServiceKind.bonus);
    final username = account.usernameLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.ctaBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.colors.surface.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.loyalty.icon, size: 20, color: accent.icon),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.hostDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        15,
                        fontWeight: FontWeight.w700,
                        color: accent.onSoft,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(
                          13,
                          color: accent.onSoft.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Баланс',
            style: AppTextStyle.base(
              13,
              color: accent.onSoft.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                account.formattedBalance,
                style: AppTextStyle.base(
                  34,
                  fontWeight: FontWeight.w800,
                  color: accent.onSoft,
                  height: 1,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  BonusFormat.bonusWord(account.balance),
                  style: AppTextStyle.base(
                    15,
                    color: accent.onSoft.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Можно списать при следующей записи к этому мастеру',
            style: AppTextStyle.base(
              12,
              color: accent.onSoft.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
