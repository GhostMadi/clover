import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/feature/notification_page/data/models/notification_actor.dart';
import 'package:clover/feature/notification_page/data/models/notification_kind.dart';
import 'package:flutter/material.dart';

class NotificationAvatarStack extends StatelessWidget {
  const NotificationAvatarStack({
    super.key,
    required this.actors,
    required this.kind,
    this.size = 44,
  });

  final List<NotificationActor> actors;
  final NotificationKind kind;
  final double size;

  static const double _overlap = 14;

  @override
  Widget build(BuildContext context) {
    final visible = actors.take(2).toList();
    final stackWidth = visible.length == 1 ? size : size + _overlap;

    return SizedBox(
      width: stackWidth + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * _overlap,
              top: 0,
              child: _ActorAvatar(actor: visible[i], size: size, showBorder: visible.length > 1),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _ReactionBadge(kind: kind),
          ),
        ],
      ),
    );
  }
}

class _ActorAvatar extends StatelessWidget {
  const _ActorAvatar({
    required this.actor,
    required this.size,
    required this.showBorder,
  });

  final NotificationActor actor;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = actor.avatarUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: showBorder ? 2 : 1.5),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.surfaceSoft,
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Icon(Icons.person_rounded, size: size * 0.45, color: AppColors.subTextColor.withValues(alpha: 0.7))
            : null,
      ),
    );
  }
}

class _ReactionBadge extends StatelessWidget {
  const _ReactionBadge({required this.kind});

  final NotificationKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (kind) {
      NotificationKind.like || NotificationKind.commentLike => (
        AppIcons.likeFilled.icon,
        Colors.red,
        AppColors.white,
      ),
      NotificationKind.dislike || NotificationKind.commentDislike => (
        AppIcons.dislikeFilled.icon,
        AppColors.textColor,
        AppColors.white,
      ),
      NotificationKind.comment => (AppIcons.comment.icon, AppColors.primary, AppColors.white),
      NotificationKind.followedYou ||
      NotificationKind.youFollowed ||
      NotificationKind.mutualFollow => (Icons.person_add_alt_1_rounded, AppColors.primary, AppColors.white),
    };

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }
}
