import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_feed_/events_page/presentation/cubit/events_feed_cubit.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post_comment/presentation/widget/post_comments_sheet.dart';
import 'package:clover/feature/_post_/post_share/presentation/widget/post_share_sheet.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_author_header.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_feed_card_details.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_media_gallery.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_media_reaction_gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Карточка ивента в ленте — визуально как [PostPage].
class EventFeedPostItem extends StatelessWidget {
  const EventFeedPostItem({super.key, required this.item});

  final PostFeedItem item;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: _AuthorRow(item: item),
          ),
          _PostMediaSection(item: item),
          _ReactionRow(item: item),
          _DetailsSection(item: item),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.item});

  final PostFeedItem item;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsFeedCubit, EventsFeedState>(
      buildWhen: (previous, current) {
        final prevItem = _findItem(previous, item.post.id);
        final nextItem = _findItem(current, item.post.id);
        if (prevItem == null || nextItem == null) return true;
        return prevItem.post.likesCount != nextItem.post.likesCount ||
            prevItem.post.dislikesCount != nextItem.post.dislikesCount ||
            prevItem.marker != nextItem.marker ||
            prevItem.bookingService != nextItem.bookingService ||
            prevItem.profileFilters != nextItem.profileFilters;
      },
      builder: (context, state) {
        final feedItem = _findItem(state, item.post.id) ?? item;
        return PostFeedCardDetails(item: feedItem);
      },
    );
  }

  PostFeedItem? _findItem(EventsFeedState state, String postId) {
    return state.mapOrNull(
      loaded: (s) {
        for (final feedItem in s.items) {
          if (feedItem.post.id == postId) return feedItem;
        }
        return null;
      },
    );
  }
}

class _PostMediaSection extends StatelessWidget {
  const _PostMediaSection({required this.item});

  final PostFeedItem item;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsFeedCubit, EventsFeedState>(
      buildWhen: (previous, current) {
        final prevItem = _findItem(previous, item.post.id);
        final nextItem = _findItem(current, item.post.id);
        if (prevItem == null || nextItem == null) return true;
        return prevItem.myReaction != nextItem.myReaction;
      },
      builder: (context, state) {
        final cubit = context.read<EventsFeedCubit>();
        final feedItem = _findItem(state, item.post.id) ?? item;

        return PostMediaReactionGestures(
          isLiked: feedItem.isLiked,
          isDisliked: feedItem.isDisliked,
          onLike: () => cubit.toggleLike(feedItem),
          onDislike: () => cubit.toggleDislike(feedItem),
          child: PostMediaGallery(media: feedItem.post.sortedMedia),
        );
      },
    );
  }

  PostFeedItem? _findItem(EventsFeedState state, String postId) {
    return state.mapOrNull(
      loaded: (s) {
        for (final feedItem in s.items) {
          if (feedItem.post.id == postId) return feedItem;
        }
        return null;
      },
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.item});

  final PostFeedItem item;

  @override
  Widget build(BuildContext context) {
    final username = item.authorUsername?.trim();
    final avatarUrl = item.authorAvatarUrl?.trim();

    return BlocBuilder<EventsFeedCubit, EventsFeedState>(
      buildWhen: (previous, current) {
        final prevItem = _findItem(previous, item.post.id);
        final nextItem = _findItem(current, item.post.id);
        if (prevItem == null || nextItem == null) return true;
        return prevItem.myFollowingAuthor != nextItem.myFollowingAuthor;
      },
      builder: (context, state) {
        final cubit = context.read<EventsFeedCubit>();
        final feedItem = _findItem(state, item.post.id) ?? item;
        final followButton = cubit.followButtonFor(feedItem);
        final isUpdating = cubit.isFollowUpdating(feedItem);

        return PostAuthorHeader(
          userId: feedItem.post.userId,
          username: username,
          avatarUrl: avatarUrl,
          trailing: followButton == null
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    switch (followButton) {
                      EventsFeedFollowButton.subscribe => AppButton(
                        text: 'Подписаться',
                        height: 40,
                        borderRadius: 14,
                        isLoading: isUpdating,
                        onTap: isUpdating ? null : () => cubit.toggleFollow(feedItem),
                      ),
                      EventsFeedFollowButton.unsubscribe => AppOutlinedButton(
                        text: 'Отписаться',
                        height: 40,
                        borderRadius: 14,
                        isLoading: isUpdating,
                        onTap: isUpdating ? null : () => cubit.toggleFollow(feedItem),
                      ),
                    },
                  ],
                ),
        );
      },
    );
  }

  PostFeedItem? _findItem(EventsFeedState state, String postId) {
    return state.mapOrNull(
      loaded: (s) {
        for (final feedItem in s.items) {
          if (feedItem.post.id == postId) return feedItem;
        }
        return null;
      },
    );
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({required this.item});

  final PostFeedItem item;

  static String? _countLabel(int count) => count > 0 ? '$count' : null;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsFeedCubit, EventsFeedState>(
      buildWhen: (previous, current) {
        final prevItem = _findItem(previous, item.post.id);
        final nextItem = _findItem(current, item.post.id);
        if (prevItem == null || nextItem == null) return true;
        return prevItem.mySaved != nextItem.mySaved ||
            prevItem.myReaction != nextItem.myReaction ||
            prevItem.post.likesCount != nextItem.post.likesCount ||
            prevItem.post.dislikesCount != nextItem.post.dislikesCount ||
            prevItem.post.commentsCount != nextItem.post.commentsCount;
      },
      builder: (context, state) {
        final cubit = context.read<EventsFeedCubit>();
        final feedItem = _findItem(state, item.post.id) ?? item;
        final post = feedItem.post;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              _ReactionIcon(
                icon: feedItem.isLiked ? AppIcons.likeFilled.icon : AppIcons.like.icon,
                label: _countLabel(post.likesCount),
                active: feedItem.isLiked,
                onTap: () => cubit.toggleLike(feedItem),
              ),
              const SizedBox(width: 4),
              _ReactionIcon(
                icon: feedItem.isDisliked ? AppIcons.dislikeFilled.icon : AppIcons.dislike.icon,
                label: _countLabel(post.dislikesCount),
                active: feedItem.isDisliked,
                activeColor: context.colors.textColor,
                onTap: () => cubit.toggleDislike(feedItem),
              ),
              const Spacer(),
              _ReactionIcon(
                icon: AppIcons.comment.icon,
                label: _countLabel(post.commentsCount),
                onTap: () async {
                  final count = await PostCommentsSheet.show(
                    context,
                    postId: post.id,
                    initialCommentsCount: post.commentsCount,
                  );
                  if (count != null && count != post.commentsCount) {
                    cubit.patchCommentsCount(post.id, count);
                  }
                },
              ),
              const SizedBox(width: 4),
              _ReactionIcon(
                icon: AppIcons.send.icon,
                label: _countLabel(post.sendsCount),
                onTap: () async {
                  final sendsCount = await PostShareSheet.show(context, postId: post.id);
                  if (sendsCount != null && sendsCount != post.sendsCount) {
                    cubit.patchSendsCount(post.id, sendsCount);
                  }
                },
              ),
              const SizedBox(width: 4),
              _ReactionIcon(
                icon: feedItem.mySaved ? AppIcons.bookmarkFilled.icon : AppIcons.bookmark.icon,
                active: feedItem.mySaved,
                activeColor: context.colors.textColor,
                onTap: () => cubit.toggleSave(feedItem),
              ),
            ],
          ),
        );
      },
    );
  }

  PostFeedItem? _findItem(EventsFeedState state, String postId) {
    return state.mapOrNull(
      loaded: (s) {
        for (final feedItem in s.items) {
          if (feedItem.post.id == postId) return feedItem;
        }
        return null;
      },
    );
  }
}

class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon({
    required this.icon,
    this.label,
    this.active = false,
    this.activeColor,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool active;
  final Color? activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? (activeColor ?? context.colors.destructive) : context.colors.textColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: color,
              ),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: AppTextStyle.base(
                    13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
