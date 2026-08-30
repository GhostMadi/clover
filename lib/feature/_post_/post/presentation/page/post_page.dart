import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_dialog.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_cluster_/cluster/data/repository/cluster_repository.dart';
import 'package:clover/feature/_post_/post/data/models/post_archive_context.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post/data/models/post_marker_summary.dart';
import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:clover/feature/_post_/post/presentation/cubit/post_detail_cubit.dart';
import 'package:clover/feature/_post_/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_cover_hero.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_detail_shimmer.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_marker_info_section.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_media_gallery.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_media_reaction_gestures.dart';
import 'package:clover/feature/_post_/post_comment/presentation/widget/post_comments_sheet.dart';
import 'package:clover/feature/_post_/post_share/presentation/widget/post_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _PostMenuAction { attach, detach, archive, unarchive, delete }

@RoutePage()
class PostPage extends StatefulWidget {
  const PostPage({
    super.key,
    required this.postId,
    this.initialPost,
    this.initialMarker,
    this.initialMyReaction,
    this.initialAuthorUsername,
    this.initialAuthorAvatarUrl,
    this.archiveContext = PostArchiveContext.none,
  });

  final String postId;
  final PostModel? initialPost;
  final PostMarkerSummary? initialMarker;

  /// `like` | `dislike` | null — из enriched-ленты профиля.
  final String? initialMyReaction;

  /// Данные автора с родительского экрана — без мигания «noName» / иконки.
  final String? initialAuthorUsername;
  final String? initialAuthorAvatarUrl;

  /// Открыт из архива — показываем «Разархивировать» вместо обычного меню.
  final PostArchiveContext archiveContext;

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  late final PostDetailCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<PostDetailCubit>()
      ..load(
        widget.postId,
        initialPost: widget.initialPost,
        initialMarker: widget.initialMarker,
        initialMyReaction: widget.initialMyReaction,
        initialAuthorUsername: widget.initialAuthorUsername,
        initialAuthorAvatarUrl: widget.initialAuthorAvatarUrl,
      );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldCollapse = _scrollController.offset > 220;
    if (shouldCollapse != _collapsed) {
      setState(() {
        _collapsed = shouldCollapse;
      });
    }
  }

  void _syncReactionToProfileFeed() {
    final item = _cubit.currentItem;
    if (item == null) return;
    try {
      context.read<PostFeedCubit>().patchPostReaction(
        postId: item.post.id,
        reaction: item.myReaction,
        post: item.post,
      );
    } catch (_) {
      // PostPage открыт вне профиля — реакция уже в PostRepository.
    }
  }

  void _syncClusterToProfileFeed() {
    final item = _cubit.currentItem;
    if (item == null) return;
    try {
      context.read<PostFeedCubit>().patchPostCluster(postId: item.post.id, post: item.post);
    } catch (_) {
      // PostPage открыт вне профиля.
    }
  }

  void _syncSavedToProfileFeed() {
    final item = _cubit.currentItem;
    if (item == null) return;
    try {
      context.read<PostFeedCubit>().patchPostSaved(
        postId: item.post.id,
        saved: item.mySaved,
        post: item.post,
      );
    } catch (_) {
      // PostPage открыт вне профиля — сохранение уже в PostRepository.
    }
  }

  @override
  void dispose() {
    _syncReactionToProfileFeed();
    _syncSavedToProfileFeed();
    _syncClusterToProfileFeed();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  PostFeedItem? _itemFromState(PostDetailState state) {
    if (state is PostDetailLoaded) return state.item;
    final seed = widget.initialPost;
    if (seed == null) return null;
    return PostFeedItem(
      post: seed,
      myReaction: widget.initialMyReaction,
      authorUsername: widget.initialAuthorUsername,
      authorAvatarUrl: widget.initialAuthorAvatarUrl,
      marker: widget.initialMarker,
    );
  }

  static String? _countLabel(int count) => count > 0 ? '$count' : null;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id.trim();

  bool _isOwnPost(PostFeedItem item) {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return false;
    return item.post.userId.trim() == uid;
  }

  bool _hasCluster(PostFeedItem item) {
    final id = item.post.clusterId?.trim();
    return id != null && id.isNotEmpty;
  }

  Future<void> _pickClusterAndAttach(PostFeedItem item) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      final clusters = await sl<ClusterRepository>().listActiveByOwnerId(uid);
      if (!mounted) return;

      if (clusters.isEmpty) {
        AppSnackBar.show(context, message: 'Сначала создайте кластер', kind: AppSnackBarKind.info);
        return;
      }

      final selectedId = await AppBottomSheet.show<String>(
        context: context,
        title: 'Кластер',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final cluster in clusters)
              AppTile(
                title: cluster.title.isNotEmpty ? cluster.title : 'Без названия',
                subtitle: cluster.postsCountLabel,
                onTap: () => Navigator.of(context).pop(cluster.id),
              ),
          ],
        ),
      );

      if (selectedId == null || !mounted) return;

      await _cubit.setPostCluster(selectedId);
      if (!mounted) return;

      _syncClusterToProfileFeed();
      AppSnackBar.show(context, message: 'Пост привязан к кластеру', kind: AppSnackBarKind.success);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось привязать пост', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _detachFromCluster() async {
    try {
      await _cubit.setPostCluster(null);
      if (!mounted) return;

      _syncClusterToProfileFeed();
      AppSnackBar.show(context, message: 'Пост отвязан от кластера', kind: AppSnackBarKind.success);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось отвязать пост', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _removeFromProfileFeed(String postId) async {
    try {
      await context.read<PostFeedCubit>().removePost(postId);
    } catch (_) {}
  }

  Future<void> _archivePost(PostFeedItem item) async {
    final isEvent = item.marker != null || item.post.hasMarker;
    final ok = await AppDialog.showConfirm(
      context: context,
      title: isEvent ? 'Архивировать ивент?' : 'Архивировать публикацию?',
      message: isEvent ? 'Событие пропадёт из ленты и карты.' : 'Публикация пропадёт из профиля.',
      confirmLabel: 'Архивировать',
      upperCaseTitle: false,
    );
    if (ok != true || !mounted) return;

    try {
      await _cubit.archivePost();
      if (!mounted) return;

      _removeFromProfileFeed(item.post.id);
      AppSnackBar.show(
        context,
        message: isEvent ? 'Ивент архивирован' : 'Публикация архивирована',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось архивировать', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _unarchivePost(PostFeedItem item) async {
    final isEvent = widget.archiveContext == PostArchiveContext.event;
    final ok = await AppDialog.showConfirm(
      context: context,
      title: isEvent ? 'Разархивировать ивент?' : 'Разархивировать публикацию?',
      message: isEvent
          ? 'Событие снова появится в ленте и на карте.'
          : 'Публикация снова появится в профиле.',
      confirmLabel: 'Разархивировать',
      upperCaseTitle: false,
    );
    if (ok != true || !mounted) return;

    try {
      await _cubit.unarchivePost(isEvent: isEvent);
      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: isEvent ? 'Ивент разархивирован' : 'Публикация разархивирована',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop(true);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось разархивировать', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _deletePost(PostFeedItem item) async {
    final isEvent = item.marker != null || item.post.hasMarker;
    final ok = await AppDialog.showConfirm(
      context: context,
      title: isEvent ? 'Удалить ивент?' : 'Удалить публикацию?',
      message: isEvent
          ? 'Событие, пост и медиа будут удалены безвозвратно.'
          : 'Публикация и медиа будут удалены безвозвратно.',
      confirmLabel: 'Удалить',
      confirmIsDestructive: true,
      upperCaseTitle: false,
    );
    if (ok != true || !mounted) return;

    try {
      await _cubit.deletePost();
      if (!mounted) return;

      await _removeFromProfileFeed(item.post.id);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: isEvent ? 'Ивент удалён' : 'Публикация удалена',
        kind: AppSnackBarKind.success,
      );
      context.router.maybePop();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось удалить', kind: AppSnackBarKind.error);
    }
  }

  List<FunctionalButtonItem> _reactionButtons(PostFeedItem item) {
    final post = item.post;
    return [
      FunctionalButtonItem(
        icon: item.isLiked ? AppIcons.likeFilled.icon : AppIcons.like.icon,
        label: _countLabel(post.likesCount),
        customColor: item.isLiked ? Colors.red : null,
        iconColor: item.isLiked ? Colors.white : null,
        textColor: item.isLiked ? Colors.white : null,
        onTap: _cubit.toggleLike,
      ),
      FunctionalButtonItem(
        icon: item.isDisliked ? AppIcons.dislikeFilled.icon : AppIcons.dislike.icon,
        label: _countLabel(post.dislikesCount),
        customColor: item.isDisliked ? Colors.red : null,
        iconColor: item.isDisliked ? Colors.white : null,
        textColor: item.isDisliked ? Colors.white : null,
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

  List<FunctionalButtonItem> _buttons(PostFeedItem item) => [
    FunctionalButtonItem(
      icon: AppIcons.back.icon,
      customColor: context.colors.primary,
      keepWhenCollapsed: true,
      onTap: () => context.router.maybePop(),
    ),
    ..._reactionButtons(item),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _syncReactionToProfileFeed();
      },
      child: BlocProvider.value(
        value: _cubit,
        child: BlocBuilder<PostDetailCubit, PostDetailState>(
          builder: (context, state) {
            final item = _itemFromState(state);
            return switch (state) {
              PostDetailInitial() || PostDetailLoading() => _buildShell(
                item: item,
                body: item != null
                    ? _buildScrollBody(item: item, isMarkerLoading: _isMarkerLoading(item))
                    : const PostDetailShimmer(),
              ),
              PostDetailError(:final message) => AppFunctionalScreen(
                collapsed: _collapsed,
                buttons: [
                  FunctionalButtonItem(
                    icon: AppIcons.back.icon,
                    customColor: context.colors.primary,
                    keepWhenCollapsed: true,
                    onTap: () => context.router.maybePop(),
                  ),
                ],
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
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
              PostDetailLoaded(:final item, :final isRefreshing, :final isFollowUpdating) => _buildLoaded(
                item,
                isRefreshing,
                isFollowUpdating,
              ),
            };
          },
        ),
      ),
    );
  }

  Widget _buildShell({required Widget body, PostFeedItem? item}) {
    return AppFunctionalScreen(
      collapsed: _collapsed,
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          customColor: context.colors.primary,
          keepWhenCollapsed: true,
          onTap: () => context.router.maybePop(),
        ),
        if (item != null) ..._reactionButtons(item),
      ],
      body: body,
    );
  }

  Widget _buildCover(String postId, PostFeedItem item) {
    final post = item.post;
    return PostMediaReactionGestures(
      isLiked: item.isLiked,
      isDisliked: item.isDisliked,
      onLike: _cubit.toggleLike,
      onDislike: _cubit.toggleDislike,
      child: PostCoverHero(
        postId: postId,
        borderRadius: const BorderRadius.all(Radius.circular(0)),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(0)),
          child: SizedBox(
            width: double.infinity,
            child: PostMediaGallery(media: post.sortedMedia),
          ),
        ),
      ),
    );
  }

  bool _isMarkerLoading(PostFeedItem item) => item.post.hasMarker && item.marker == null;

  Widget _buildScrollBody({
    required PostFeedItem item,
    bool isRefreshing = false,
    bool isFollowUpdating = false,
    bool? isMarkerLoading,
  }) {
    final post = item.post;
    final title = post.title?.trim();
    final description = post.description?.trim();
    final authorUsername = item.authorUsername ?? widget.initialAuthorUsername;
    final markerLoading = isMarkerLoading ?? _isMarkerLoading(item);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
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

          SliverToBoxAdapter(child: _buildCover(widget.postId, item)),
          SliverToBoxAdapter(
            child: PostMarkerInfoSection(
              marker: item.marker,
              title: title,
              description: description,
              username: authorUsername,
              likesCount: post.likesCount,
              dislikesCount: post.dislikesCount,
              isMarkerLoading: markerLoading,
              profileFilters: item.profileFilters,
              postTextEmoji: post.textEmoji,
              postTags: post.tags,
              postAddressPrimary: post.addressPrimary,
              postAddressCyrillic: post.addressCyrillic,
              postCountryCode: post.countryCode,
              postCityCode: post.cityCode,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppFunctionalScreen.scrollBottomClearance(context))),
        ],
      ),
    );
  }

  Widget _buildLoaded(PostFeedItem item, bool isRefreshing, bool isFollowUpdating) {
    return AppFunctionalScreen(
      collapsed: _collapsed,
      buttons: _buttons(item),
      body: _buildScrollBody(
        item: item,
        isRefreshing: isRefreshing,
        isFollowUpdating: isFollowUpdating,
        isMarkerLoading: _isMarkerLoading(item),
      ),
    );
  }

  Widget _buildAuthorRow(PostFeedItem item, {required bool isFollowUpdating}) {
    final username = item.authorUsername?.trim();
    final avatarUrl = item.authorAvatarUrl?.trim();
    final isOwnPost = _isOwnPost(item);
    final isFollowing = item.myFollowingAuthor ?? false;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.borderSoft),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: context.colors.surfaceSoft,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Icon(Icons.person, color: context.colors.iconMuted, size: 22)
                : null,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            username ?? 'noName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
          ),
        ),
        if (!isOwnPost && item.myFollowingAuthor != null) ...[
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
        if (isOwnPost) ...[
          const SizedBox(width: 4),
          AppMiniMenu<_PostMenuAction>(
            iconPadding: const EdgeInsets.all(8),
            items: widget.archiveContext != PostArchiveContext.none
                ? [
                    AppMiniMenuItem(
                      value: _PostMenuAction.unarchive,
                      title: 'Разархивировать',
                      icon: AppIcons.unarchive.icon,
                    ),
                  ]
                : [
                    if (_hasCluster(item))
                      const AppMiniMenuItem(
                        value: _PostMenuAction.detach,
                        title: 'Отвязать от кластера',
                        icon: Icons.link_off_outlined,
                      )
                    else
                      const AppMiniMenuItem(
                        value: _PostMenuAction.attach,
                        title: 'Привязать к кластеру',
                        icon: Icons.collections_outlined,
                      ),
                    AppMiniMenuItem(
                      value: _PostMenuAction.archive,
                      title: 'Архивировать',
                      icon: AppIcons.archive.icon,
                    ),
                    AppMiniMenuItem(
                      value: _PostMenuAction.delete,
                      title: 'Удалить',
                      icon: AppIcons.delete.icon,
                      titleColor: context.colors.error,
                      iconColor: context.colors.error,
                    ),
                  ],
            onSelected: (action) {
              switch (action) {
                case _PostMenuAction.attach:
                  _pickClusterAndAttach(item);
                case _PostMenuAction.detach:
                  _detachFromCluster();
                case _PostMenuAction.archive:
                  _archivePost(item);
                case _PostMenuAction.unarchive:
                  _unarchivePost(item);
                case _PostMenuAction.delete:
                  _deletePost(item);
              }
            },
          ),
        ],
      ],
    );
  }
}
