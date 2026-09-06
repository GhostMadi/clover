import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post/presentation/cubit/post_detail_cubit.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_author_header.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_cover_hero.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_detail_shimmer.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_feed_card_details.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_media_gallery.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_media_reaction_gestures.dart';
import 'package:clover/feature/_post_/post_comment/presentation/widget/post_comments_sheet.dart';
import 'package:clover/feature/_post_/post_share/presentation/widget/post_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Шторка маркера: тот же детальный просмотр, что [PostPage], но в `AppBottomSheet`.
abstract final class MapMarkerPostSheet {
  static Future<void> show(BuildContext context, {required String postId}) async {
    final height = MediaQuery.sizeOf(context).height * 0.86;

    await AppBottomSheet.show<void>(
      context: context,
      upperCaseTitle: false,
      showCloseButton: false,
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
  late final PostDetailCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<PostDetailCubit>()..load(widget.postId);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldCollapse = _scrollController.offset > 220;
    if (shouldCollapse != _collapsed) {
      setState(() => _collapsed = shouldCollapse);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  static String? _countLabel(int count) => count > 0 ? '$count' : null;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id.trim();

  bool _isOwnPost(PostFeedItem item) {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return false;
    return item.post.userId.trim() == uid;
  }

  List<FunctionalButtonItem> _reactionButtons(PostFeedItem item) {
    final post = item.post;
    return [
      FunctionalButtonItem(
        icon: item.isLiked ? AppIcons.likeFilled.icon : AppIcons.like.icon,
        label: _countLabel(post.likesCount),
        customColor: item.isLiked ? context.colors.destructive : null,
        iconColor: item.isLiked ? context.colors.textInverse : null,
        textColor: item.isLiked ? context.colors.textInverse : null,
        onTap: _cubit.toggleLike,
      ),
      FunctionalButtonItem(
        icon: item.isDisliked ? AppIcons.dislikeFilled.icon : AppIcons.dislike.icon,
        label: _countLabel(post.dislikesCount),
        customColor: item.isDisliked ? context.colors.destructive : null,
        iconColor: item.isDisliked ? context.colors.textInverse : null,
        textColor: item.isDisliked ? context.colors.textInverse : null,
        onTap: _cubit.toggleDislike,
      ),
      FunctionalButtonItem(
        icon: AppIcons.comment.icon,
        label: _countLabel(post.commentsCount),
        onTap: () async {
          final count = await PostCommentsSheet.show(
            context,
            postId: post.id,
            initialCommentsCount: post.commentsCount,
          );
          if (count != null && count != post.commentsCount) {
            _cubit.patchCommentsCount(count);
          }
        },
      ),
      FunctionalButtonItem(
        icon: AppIcons.send.icon,
        label: _countLabel(post.sendsCount),
        onTap: () async {
          final sendsCount = await PostShareSheet.show(context, postId: post.id);
          if (sendsCount != null && sendsCount != post.sendsCount) {
            _cubit.patchSendsCount(sendsCount);
          }
        },
      ),
      FunctionalButtonItem(
        icon: item.mySaved ? AppIcons.bookmarkFilled.icon : AppIcons.bookmark.icon,
        iconColor: item.mySaved ? context.colors.textColor : null,
        onTap: _cubit.toggleSave,
      ),
    ];
  }

  List<FunctionalButtonItem> _buttons(PostFeedItem? item) => [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          customColor: context.colors.primary,
          keepWhenCollapsed: true,
          onTap: _close,
        ),
        if (item != null) ..._reactionButtons(item),
      ];

  bool _isMarkerLoading(PostFeedItem item, {required bool isRefreshing}) =>
      isRefreshing && item.isMarkerPayloadPending;

  bool _isBookingServiceLoading(PostFeedItem item, {required bool isRefreshing}) =>
      isRefreshing && item.isBookingServicePayloadPending;

  Widget _buildCover(PostFeedItem item) {
    return PostMediaReactionGestures(
      isLiked: item.isLiked,
      isDisliked: item.isDisliked,
      onLike: _cubit.toggleLike,
      onDislike: _cubit.toggleDislike,
      child: PostCoverHero(
        postId: widget.postId,
        borderRadius: const BorderRadius.all(Radius.circular(0)),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(0)),
          child: SizedBox(
            width: double.infinity,
            child: PostMediaGallery(media: item.post.sortedMedia),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorRow(PostFeedItem item, {required bool isFollowUpdating}) {
    final isOwnPost = _isOwnPost(item);
    final isFollowing = item.myFollowingAuthor ?? false;

    return PostAuthorHeader(
      userId: item.post.userId,
      username: item.authorUsername,
      avatarUrl: item.authorAvatarUrl,
      trailing: !isOwnPost && item.myFollowingAuthor != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                if (isFollowing)
                  AppOutlinedButton(
                    text: 'Отписаться',
                    height: 40,
                    borderRadius: 14,
                    isLoading: isFollowUpdating,
                    onTap: _cubit.toggleFollow,
                  )
                else
                  AppButton(
                    text: 'Подписаться',
                    height: 40,
                    borderRadius: 14,
                    isLoading: isFollowUpdating,
                    onTap: _cubit.toggleFollow,
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildScrollBody({
    required PostFeedItem item,
    bool isRefreshing = false,
    bool isFollowUpdating = false,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (isRefreshing)
          SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2, color: context.colors.primary)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildAuthorRow(item, isFollowUpdating: isFollowUpdating),
          ),
        ),
        SliverToBoxAdapter(child: _buildCover(item)),
        SliverToBoxAdapter(
          child: PostFeedCardDetails(
            item: item,
            isMarkerLoading: _isMarkerLoading(item, isRefreshing: isRefreshing),
            isBookingServiceLoading: _isBookingServiceLoading(item, isRefreshing: isRefreshing),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppFunctionalScreen.scrollBottomClearance(context))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PostDetailCubit, PostDetailState>(
        builder: (context, state) {
          return switch (state) {
            PostDetailInitial() || PostDetailLoading() => AppFunctionalScreen(
                collapsed: _collapsed,
                buttons: _buttons(null),
                body: const PostDetailShimmer(showMarkerBlock: true),
              ),
            PostDetailError(:final message) => AppFunctionalScreen(
                collapsed: _collapsed,
                buttons: _buttons(null),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(14, color: context.colors.subTextColor),
                        ),
                        const SizedBox(height: 12),
                        AppButton(text: 'Повторить', onTap: _cubit.reload),
                      ],
                    ),
                  ),
                ),
              ),
            PostDetailLoaded(:final item, :final isRefreshing, :final isFollowUpdating) => AppFunctionalScreen(
                collapsed: _collapsed,
                buttons: _buttons(item),
                body: _buildScrollBody(
                  item: item,
                  isRefreshing: isRefreshing,
                  isFollowUpdating: isFollowUpdating,
                ),
              ),
          };
        },
      ),
    );
  }
}
