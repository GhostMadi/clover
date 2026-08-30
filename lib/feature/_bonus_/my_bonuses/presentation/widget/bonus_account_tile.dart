import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:clover/feature/_bonus_/shared/data/bonus_format.dart';
import 'package:flutter/material.dart';

class BonusAccountTile extends StatelessWidget {
  const BonusAccountTile({super.key, required this.item, this.onProfileTap, this.onHistoryTap});

  final BonusAccountItem item;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHistoryTap;

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = item.avatarUrl?.trim();
    final username = item.usernameLabel;
    final borderRadius = BorderRadius.circular(_radius);

    void openProfile() {
      if (onProfileTap != null) {
        onProfileTap!();
        return;
      }
      context.router.push(GuestProfileRoute(userId: item.hostId));
    }

    void openHistory() {
      if (onHistoryTap != null) {
        onHistoryTap!();
        return;
      }
      context.router.push(BonusHistoryRoute(account: item));
    }

    return Container(
      decoration: _neonOuterDecoration(borderRadius, context.colors),
      child: Container(
        decoration: _neonInnerDecoration(borderRadius, context.colors),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TileTapZone(
                  onTap: openProfile,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(_radius)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                    child: Row(
                      children: [
                        _Avatar(avatarUrl: avatarUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.hostDisplayName,
                                maxLines: 2,
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
                      ],
                    ),
                  ),
                ),
              ),
              const _NeonDivider(),
              _TileTapZone(
                onTap: openHistory,
                borderRadius: BorderRadius.horizontal(right: Radius.circular(_radius)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BalanceColumn(item: item),
                      const SizedBox(width: 4),
                      Icon(
                        AppIcons.chevronRight.icon,
                        color: context.colors.primary.withValues(alpha: 0.55),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static BoxDecoration _neonOuterDecoration(BorderRadius borderRadius, AppPalette colors) {
    return BoxDecoration(
      borderRadius: borderRadius,
      boxShadow: [
        BoxShadow(color: colors.primary.withValues(alpha: 0.32), blurRadius: 14),
        BoxShadow(color: colors.primary.withValues(alpha: 0.14), blurRadius: 28, spreadRadius: 1),
      ],
    );
  }

  static BoxDecoration _neonInnerDecoration(BorderRadius borderRadius, AppPalette colors) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: borderRadius,
      border: Border.all(color: colors.primary.withValues(alpha: 0.42), width: 1.2),
    );
  }
}

class _TileTapZone extends StatelessWidget {
  const _TileTapZone({required this.onTap, required this.borderRadius, required this.child});

  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: context.colors.primary.withValues(alpha: 0.08),
        highlightColor: context.colors.primary.withValues(alpha: 0.04),
        child: child,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [BoxShadow(color: context.colors.primary.withValues(alpha: 0.35), blurRadius: 10)],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(avatarUrl!, fit: BoxFit.cover, width: 48, height: 48)
            : ColoredBox(
                color: context.colors.surfaceSoft,
                child: Icon(AppIcons.personRounded.icon, size: 26, color: context.colors.primary.withValues(alpha: 0.7)),
              ),
      ),
    );
  }
}

class _NeonDivider extends StatelessWidget {
  const _NeonDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.colors.primary.withValues(alpha: 0.05),
            context.colors.primary.withValues(alpha: 0.75),
            context.colors.primary.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [BoxShadow(color: context.colors.primary.withValues(alpha: 0.45), blurRadius: 8)],
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({required this.item});

  final BonusAccountItem item;

  @override
  Widget build(BuildContext context) {
    final neonShadow = [
      Shadow(color: context.colors.primary.withValues(alpha: 0.6), blurRadius: 10),
      Shadow(color: context.colors.primary.withValues(alpha: 0.25), blurRadius: 18),
    ];

    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.formattedBalance,
            textAlign: TextAlign.right,
            style: AppTextStyle.base(
              20,
              color: context.colors.primary,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.3,
            ).copyWith(shadows: neonShadow),
          ),
          const SizedBox(height: 2),
          Text(
            BonusFormat.bonusWord(item.balance),
            textAlign: TextAlign.right,
            style: AppTextStyle.base(11, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
