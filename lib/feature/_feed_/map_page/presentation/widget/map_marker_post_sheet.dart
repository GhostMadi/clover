import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_reaction_math.dart';
import 'package:clover/feature/post/data/repository/post_repository.dart';
import 'package:clover/feature/post/presentation/widget/post_detail_shimmer.dart';
import 'package:clover/feature/post/presentation/widget/post_marker_info_section.dart';
import 'package:clover/feature/post/presentation/widget/post_media_gallery.dart';
import 'package:clover/feature/post/presentation/widget/post_media_reaction_gestures.dart';
import 'package:clover/feature/post_comment/presentation/widget/post_comments_sheet.dart';
import 'package:clover/feature/post_share/presentation/widget/post_share_sheet.dart';
import 'package:flutter/material.dart';

/// Шторка с постом маркера (как карточка в ленте ивентов).
abstract final class MapMarkerPostSheet {
  static Future<void> show(BuildContext context, {required String postId}) async {
    final height = MediaQuery.sizeOf(context).height * 0.86;

    await AppBottomSheet.show<void>(
      context: context,
      upperCaseTitle: false,
      showCloseButton: true,
      postFeedSurface: true,
      contentHeight: height,
      expandBody: true,
      contentPadding: EdgeInsets.zero,
      contentBottomSpacing: 0,
      sheetOuterPadding: const EdgeInsets.fromLTRB(12, 80, 12, 12),
      content: _MapMarkerPostSheetBody(postId: postId),
    );
  }
}

class _MapMarkerPostSheetBody extends StatefulWidget {
  const _MapMarkerPostSheetBody({required this.postId});

  final String postId;

  @override
  State<_MapMarkerPostSheetBody> createState() => _MapMarkerPostSheetBodyState();
}

class _MapMarkerPostSheetBodyState extends State<_MapMarkerPostSheetBody> {
  final _repository = sl<PostRepository>();

  PostFeedItem? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _item = null;
    });

    try {
      final remote = await _repository.getPostEnriched(widget.postId);
      if (!mounted) return;

      setState(() {
        _item = remote ?? _repository.getCachedFeedItem(widget.postId);
        _loading = false;
        if (_item == null) _error = 'Пост недоступен';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _item = _repository.getCachedFeedItem(widget.postId);
        _loading = false;
        if (_item == null) _error = 'Не удалось загрузить пост';
      });
    }
  }

  Future<void> _toggleLike() async {
    final item = _item;
    if (item == null) return;
    await _setReaction(item, item.isLiked ? null : 'like');
  }

  Future<void> _toggleDislike() async {
    final item = _item;
    if (item == null) return;
    await _setReaction(item, item.isDisliked ? null : 'dislike');
  }

  Future<void> _setReaction(PostFeedItem item, String? next) async {
    final postId = item.post.id.trim();
    if (postId.isEmpty) return;

    final from = item.myReaction;
    final normalized = _normalizeReaction(next);
    if (from == normalized) return;

    final optimisticPost = PostReactionMath.apply(post: item.post, from: from, to: normalized);
    final optimistic = item.copyWith(
      post: optimisticPost,
      myReaction: normalized,
      clearMyReaction: normalized == null,
    );

    _repository.cacheMyReaction(postId, normalized);
    _repository.cacheFeedItem(optimistic);
    setState(() => _item = optimistic);

    try {
      final confirmed = await _repository.setPostReaction(postId, normalized);
      if (!mounted) return;

      final current = _item;
      if (current == null || current.post.id != postId || current.myReaction != normalized) return;

      final confirmedReaction = _normalizeReaction(confirmed);
      _repository.cacheMyReaction(postId, confirmedReaction);
      if (confirmedReaction == normalized) return;

      final reconciledPost = PostReactionMath.apply(post: item.post, from: from, to: confirmedReaction);
      final reconciled = item.copyWith(
        post: reconciledPost,
        myReaction: confirmedReaction,
        clearMyReaction: confirmedReaction == null,
      );
      _repository.cacheFeedItem(reconciled);
      setState(() => _item = reconciled);
    } catch (_) {
      if (!mounted) return;
      final current = _item;
      if (current == null || current.post.id != postId || current.myReaction != normalized) return;
      _repository.cacheMyReaction(postId, from);
      _repository.cacheFeedItem(item);
      setState(() => _item = item);
    }
  }

  String? _normalizeReaction(String? value) {
    final v = value?.trim();
    if (v == 'like' || v == 'dislike') return v;
    return null;
  }

  Future<void> _toggleSave() async {
    final item = _item;
    if (item == null) return;

    final next = !item.mySaved;
    setState(() => _item = item.copyWith(mySaved: next));
    await _repository.setPostSaved(item.post.id, next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: AppColors.pageBackground,
        child: PostDetailShimmer(showMarkerBlock: true),
      );
    }

    if (_item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? 'Пост недоступен',
            textAlign: TextAlign.center,
            style: AppTextStyle.base(15, color: AppColors.subTextColor),
          ),
        ),
      );
    }

    final item = _item!;
    final post = item.post;
    final title = post.title?.trim();
    final description = post.description?.trim();

    return ColoredBox(
      color: AppColors.pageBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _AuthorRow(item: item),
          PostMediaReactionGestures(
            isLiked: item.isLiked,
            isDisliked: item.isDisliked,
            onLike: _toggleLike,
            onDislike: _toggleDislike,
            child: PostMediaGallery(media: post.sortedMedia),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                _ReactionIcon(
                  icon: item.isLiked ? AppIcons.likeFilled.icon : AppIcons.like.icon,
                  label: _countLabel(post.likesCount),
                  active: item.isLiked,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 4),
                _ReactionIcon(
                  icon: item.isDisliked ? AppIcons.dislikeFilled.icon : AppIcons.dislike.icon,
                  label: _countLabel(post.dislikesCount),
                  active: item.isDisliked,
                  onTap: _toggleDislike,
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
                    if (count != null && mounted && count != post.commentsCount) {
                      setState(() => _item = item.copyWith(post: post.copyWith(commentsCount: count)));
                    }
                  },
                ),
                const SizedBox(width: 4),
                _ReactionIcon(
                  icon: AppIcons.send.icon,
                  label: _countLabel(post.sendsCount),
                  onTap: () async {
                    final sendsCount = await PostShareSheet.show(context, postId: post.id);
                    if (sendsCount != null && mounted && sendsCount != post.sendsCount) {
                      setState(() => _item = item.copyWith(post: post.copyWith(sendsCount: sendsCount)));
                    }
                  },
                ),
                const SizedBox(width: 4),
                _ReactionIcon(
                  icon: item.mySaved ? AppIcons.bookmarkFilled.icon : AppIcons.bookmark.icon,
                  active: item.mySaved,
                  activeColor: AppColors.textColor,
                  onTap: _toggleSave,
                ),
              ],
            ),
          ),
          PostMarkerInfoSection(
            marker: item.marker,
            title: title,
            description: description,
            username: item.authorUsername,
            likesCount: post.likesCount,
            dislikesCount: post.dislikesCount,
          ),
        ],
      ),
    );
  }

  static String? _countLabel(int count) => count > 0 ? '$count' : null;
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.item});

  final PostFeedItem item;

  @override
  Widget build(BuildContext context) {
    final username = item.authorUsername?.trim();
    final avatarUrl = item.authorAvatarUrl?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSoft, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceSoft,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Icon(Icons.person_rounded, size: 20, color: AppColors.subTextColor.withValues(alpha: 0.7))
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username != null && username.isNotEmpty ? '@$username' : 'Автор',
              style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon({
    required this.icon,
    this.label,
    this.active = false,
    this.activeColor = Colors.red,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : AppColors.textColor;

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
              Icon(icon, size: 24, color: color),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(label!, style: AppTextStyle.base(13, color: color, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
