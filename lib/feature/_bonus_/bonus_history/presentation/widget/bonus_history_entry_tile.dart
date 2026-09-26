import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_bonus_/bonus_history/data/models/bonus_history_entry.dart';
import 'package:flutter/material.dart';

class BonusHistoryEntryTile extends StatelessWidget {
  const BonusHistoryEntryTile({super.key, required this.entry, this.showDivider = true});

  final BonusHistoryEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.serviceAccent(AppServiceKind.bonus);
    final date = entry.occurredAt.toLocal();
    final dateLabel = '${context.dateFormat.dayMonth(date)}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final amountColor = entry.isCredit ? accent.icon : context.colors.destructive;
    final badgeBg = entry.isCredit ? accent.soft : context.colors.surfaceMuted;
    final badgeIcon = entry.isCredit ? AppIcons.addRounded.icon : AppIcons.removeRounded.icon;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                child: Icon(
                  badgeIcon,
                  size: 18,
                  color: entry.isCredit ? accent.icon : context.colors.subTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: AppTextStyle.base(
                        15,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textColor,
                      ),
                    ),
                    if (entry.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle,
                        style: AppTextStyle.base(
                          13,
                          color: context.colors.subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: AppTextStyle.base(12, color: context.colors.iconMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.amountLabel,
                style: AppTextStyle.base(17, fontWeight: FontWeight.w800, color: amountColor),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: context.colors.divider.withValues(alpha: 0.8)),
      ],
    );
  }
}
