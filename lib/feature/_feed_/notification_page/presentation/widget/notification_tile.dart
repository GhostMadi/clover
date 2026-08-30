import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_actor.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_item.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_kind.dart';
import 'package:clover/feature/_feed_/notification_page/presentation/widget/notification_avatar_stack.dart';
import 'package:flutter/material.dart';

class NotificationTile extends StatefulWidget {
  const NotificationTile({
    super.key,
    required this.item,
    this.onFollowToggle,
    this.onTap,
  });

  final NotificationItem item;
  final ValueChanged<NotificationItem>? onFollowToggle;
  final VoidCallback? onTap;

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  late bool _isFollowing = widget.item.isFollowingActor;

  @override
  void didUpdateWidget(covariant NotificationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _isFollowing = widget.item.isFollowingActor;
    }
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    widget.onFollowToggle?.call(widget.item.copyWith(isFollowingActor: _isFollowing));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final text = _buildMessage(item);
    final timeLabel = _formatRelativeTime(item.createdAt);
    final showPostPreview = item.postPreviewUrl != null &&
        (item.kind == NotificationKind.like ||
            item.kind == NotificationKind.dislike ||
            item.kind == NotificationKind.comment ||
            item.kind == NotificationKind.commentLike ||
            item.kind == NotificationKind.commentDislike);

    return Material(
      color: item.isUnread ? AppColors.bgSoftMint.withValues(alpha: 0.55) : AppColors.pageBackground,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationAvatarStack(actors: item.actors, kind: item.kind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyle.base(14, color: AppColors.textColor, height: 1.35),
                        children: text,
                      ),
                    ),
                    if (item.commentPreview case final preview? when preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(13, color: AppColors.subTextColor, height: 1.3),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: AppTextStyle.base(12, color: AppColors.subTextColor.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (item.showFollowButton)
                _FollowButton(isFollowing: _isFollowing, onTap: _toggleFollow)
              else if (showPostPreview)
                _PostPreview(url: item.postPreviewUrl!),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildMessage(NotificationItem item) {
    final actorsLabel = _actorsLabel(item.actors);
    final bold = (String text) => TextSpan(
      text: text,
      style: AppTextStyle.base(14, color: AppColors.textColor, fontWeight: FontWeight.w700, height: 1.35),
    );
    final regular = (String text) => TextSpan(
      text: text,
      style: AppTextStyle.base(14, color: AppColors.textColor, height: 1.35),
    );

    return switch (item.kind) {
      NotificationKind.followedYou => [bold(actorsLabel), regular(' подписался(-ась) на вас')],
      NotificationKind.youFollowed => [regular('Вы подписались на '), bold(actorsLabel)],
      NotificationKind.mutualFollow => [
        bold(actorsLabel),
        regular(' подписался(-ась) на вас. Вы подписаны друг на друга'),
      ],
      NotificationKind.like => _reactionMessage(actorsLabel, 'лайкнули', 'ваш пост', bold, regular),
      NotificationKind.dislike => _reactionMessage(actorsLabel, 'дизлайкнули', 'ваш пост', bold, regular),
      NotificationKind.comment => item.isReply
          ? _reactionMessage(actorsLabel, 'ответил(а)', 'на ваш комментарий', bold, regular)
          : _reactionMessage(actorsLabel, 'прокомментировал(а)', 'ваш пост', bold, regular),
      NotificationKind.commentLike => _reactionMessage(actorsLabel, 'лайкнули', 'ваш комментарий', bold, regular),
      NotificationKind.commentDislike => _reactionMessage(actorsLabel, 'дизлайкнули', 'ваш комментарий', bold, regular),
    };
  }

  List<InlineSpan> _reactionMessage(
    String actorsLabel,
    String verb,
    String target,
    TextSpan Function(String) bold,
    TextSpan Function(String) regular,
  ) {
    return [bold(actorsLabel), regular(' $verb $target')];
  }

  String _actorsLabel(List<NotificationActor> actors) {
    if (actors.isEmpty) return 'Кто-то';
    if (actors.length == 1) return actors.first.displayName;
    if (actors.length == 2) return '${actors[0].displayName} и ${actors[1].displayName}';
    return '${actors[0].displayName}, ${actors[1].displayName} и ещё ${actors.length - 2}';
  }

  String _formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин.';
    if (diff.inHours < 24) return '${diff.inHours} ч.';
    if (diff.inDays < 7) return '${diff.inDays} д.';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.isFollowing, required this.onTap});

  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isFollowing) {
      return AppOutlinedButton(
        text: 'Подписаны',
        height: 34,
        borderRadius: 10,
        onTap: onTap,
      );
    }

    return AppButton(
      text: 'Подписаться',
      height: 34,
      borderRadius: 10,
      onTap: onTap,
    );
  }
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 44,
          height: 44,
          color: AppColors.surfaceSoft,
          child: Icon(Icons.image_outlined, size: 20, color: AppColors.subTextColor.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
