import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_post_/post_comment/data/models/comment_item.dart';
import 'package:clover/feature/_post_/post_comment/data/models/comment_model.dart';
import 'package:clover/feature/_post_/post_comment/presentation/widget/comment_time_format.dart';
import 'package:flutter/material.dart';

class PostCommentTile extends StatelessWidget {
  const PostCommentTile({
    super.key,
    required this.item,
    required this.onLikeTap,
    required this.onReplyTap,
    this.dense = false,
  });

  final CommentItem item;
  final VoidCallback onLikeTap;
  final VoidCallback onReplyTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final username = item.authorUsername?.trim();
    final avatarUrl = item.authorAvatarUrl?.trim();
    final likesLabel = item.comment.likesCount > 0 ? '${item.comment.likesCount}' : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(dense ? 44 : 16, dense ? 8 : 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: dense ? 14 : 18,
            backgroundColor: context.colors.surfaceSoft,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Icon(AppIcons.user.icon, size: dense ? 16 : 20, color: context.colors.iconMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyle.base(14, color: context.colors.textColor, height: 1.35),
                    children: [
                      TextSpan(
                        text: username ?? 'noName',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(text: item.comment.text),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      CommentTimeFormat.format(item.comment.createdAt),
                      style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReplyTap,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Ответить',
                        style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              InkWell(
                onTap: onLikeTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    item.isLiked ? AppIcons.likeFilled.icon : AppIcons.like.icon,
                    size: 16,
                    color: item.isLiked ? Colors.red : context.colors.subTextColor,
                  ),
                ),
              ),
              if (likesLabel != null)
                Text(
                  likesLabel,
                  style: AppTextStyle.base(11, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PostCommentRepliesToggle extends StatelessWidget {
  const PostCommentRepliesToggle({
    super.key,
    required this.repliesCount,
    required this.expanded,
    required this.loading,
    required this.onTap,
  });

  final int repliesCount;
  final bool expanded;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (repliesCount <= 0 && !expanded) return const SizedBox.shrink();

    final label = loading
        ? 'Загрузка…'
        : expanded
        ? 'Скрыть ответы'
        : 'Посмотреть ответы ($repliesCount)';

    return Padding(
      padding: const EdgeInsets.only(left: 58, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: loading ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Text(
          label,
          style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

typedef CommentReplyTap = void Function(CommentModel comment);
