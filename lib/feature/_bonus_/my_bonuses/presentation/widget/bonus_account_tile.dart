import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:clover/feature/_bonus_/shared/data/bonus_format.dart';
import 'package:clover/feature/_bonus_/shared/data/bonus_mock.dart';
import 'package:flutter/material.dart';

/// Строка кошелька: мастер слева, баланс справа → история.
class BonusAccountTile extends StatelessWidget {
  const BonusAccountTile({super.key, required this.item, this.onTap});

  final BonusAccountItem item;
  final VoidCallback? onTap;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.serviceAccent(AppServiceKind.bonus);
    final avatarUrl = item.avatarUrl?.trim();
    final username = item.usernameLabel;
    final borderRadius = BorderRadius.circular(_radius);

    void open() {
      if (onTap != null) {
        onTap!();
        return;
      }
      context.router.push(BonusHistoryRoute(account: item));
    }

    return Material(
      color: context.colors.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: open,
        onLongPress: _canOpenProfile(item.hostId)
            ? () => context.router.push(GuestProfileRoute(userId: item.hostId))
            : null,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: context.colors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              _Avatar(avatarUrl: avatarUrl, soft: accent.soft, iconColor: accent.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.hostDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        16,
                        color: context.colors.textColor,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(
                          13,
                          color: context.colors.subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.formattedBalance,
                    style: AppTextStyle.base(
                      18,
                      color: accent.icon,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    BonusFormat.bonusWord(item.balance),
                    style: AppTextStyle.base(
                      11,
                      color: context.colors.subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              Icon(AppIcons.chevronRight.icon, color: context.colors.iconMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  static bool _canOpenProfile(String hostId) {
    if (BonusMock.enabled && hostId.startsWith('mock_')) return false;
    return hostId.trim().isNotEmpty;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.soft, required this.iconColor});

  final String? avatarUrl;
  final Color soft;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: 48,
        height: 48,
        child: hasImage
            ? Image.network(avatarUrl!, fit: BoxFit.cover)
            : ColoredBox(
                color: soft,
                child: Icon(AppIcons.personRounded.icon, size: 24, color: iconColor),
              ),
      ),
    );
  }
}
