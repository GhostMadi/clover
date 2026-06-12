import 'dart:async'; // Не забудь добавить импорт для Timer

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:clover/feature/post/presentation/cubit/post_detail_cubit.dart';
import 'package:clover/feature/post/presentation/widget/post_cover_hero.dart';
import 'package:clover/feature/post/presentation/widget/post_media_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class PostPage extends StatefulWidget {
  const PostPage({super.key, required this.postId, this.initialPost});

  final String postId;
  final PostModel? initialPost;

  @override
  State<PostPage> createState() => _PostPageState();
}

// Добавляем SingleTickerProviderStateMixin для работы анимаций
class _PostPageState extends State<PostPage> with SingleTickerProviderStateMixin {
  late final PostDetailCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  bool _collapsed = false;

  // Локальное состояние для лайков и дизлайков
  bool _isLiked = false;
  bool _isDisliked = false;

  // --- Переменные для кастомной обработки тапов ---
  int _tapCount = 0;
  Timer? _tapTimer;

  // --- Переменные для визуального эффекта ---
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  IconData? _overlayIcon; // Какую иконку анимировать (сердце или дизлайк)
  Color _overlayIconColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _cubit = sl<PostDetailCubit>()..load(widget.postId, initialPost: widget.initialPost);
    _scrollController.addListener(_onScroll);

    // Инициализация анимации всплывающего эффекта
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_animationController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 0.9), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 0.0), weight: 20),
    ]).animate(_animationController);
  }

  void _onScroll() {
    final shouldCollapse = _scrollController.offset > 220;
    if (shouldCollapse != _collapsed) {
      setState(() {
        _collapsed = shouldCollapse;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    _tapTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Функция обработки множественных тапов
  void _handleTap() {
    _tapCount++;
    _tapTimer?.cancel();

    _tapTimer = Timer(const Duration(milliseconds: 300), () {
      if (_tapCount == 2) {
        _triggerLikeVisual();
      } else if (_tapCount >= 3) {
        _triggerDislikeVisual();
      }
      _tapCount = 0; // Сбрасываем счетчик
    });
  }

  // Запуск эффекта ЛАЙКА
  void _triggerLikeVisual() {
    if (!_isLiked) {
      _toggleLike();
    }
    setState(() {
      _overlayIcon = AppIcons.likeFilled.icon;
      _overlayIconColor = Colors.red.withOpacity(0.95);
    });
    _animationController.forward(from: 0.0);
  }

  // Запуск эффекта ДИЗЛАЙКА
  void _triggerDislikeVisual() {
    if (!_isDisliked) {
      _toggleDislike();
    }
    setState(() {
      _overlayIcon = AppIcons.dislikeFilled.icon;
      _overlayIconColor = Colors.black.withOpacity(0.8);
    });
    _animationController.forward(from: 0.0);
  }

  // Логика переключения ЛАЙКА (локальная)
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _isDisliked = false;
      }
    });
  }

  // Логика переключения ДИЗЛАЙКА (локальная)
  void _toggleDislike() {
    setState(() {
      _isDisliked = !_isDisliked;
      if (_isDisliked) {
        _isLiked = false;
      }
    });
  }

  int _getLikesCount(int originalCount) => _isLiked ? originalCount + 1 : originalCount;
  int _getDislikesCount(int originalCount) => _isDisliked ? originalCount + 1 : originalCount;

  static String? _countLabel(int count) => count > 0 ? '$count' : null;

  static String _formatDate(DateTime date) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  List<FunctionalButtonItem> _buttons(PostModel post, PostFeedItem item) => [
    FunctionalButtonItem(
      icon: AppIcons.back.icon,
      customColor: AppColors.primary,
      keepWhenCollapsed: true,
      onTap: () => context.router.maybePop(),
    ),
    FunctionalButtonItem(
      icon: _isLiked ? AppIcons.likeFilled.icon : AppIcons.like.icon,
      label: _countLabel(_getLikesCount(post.likesCount)),
      customColor: _isLiked ? Colors.red : null,
      iconColor: _isLiked ? Colors.white : null,
      textColor: _isLiked ? Colors.white : null,
      onTap: _toggleLike,
    ),
    FunctionalButtonItem(
      icon: _isDisliked ? AppIcons.dislikeFilled.icon : AppIcons.dislike.icon,
      label: _countLabel(_getDislikesCount(post.dislikesCount)),
      customColor: _isDisliked ? Colors.red : null,
      iconColor: _isDisliked ? Colors.white : null,
      textColor: _isDisliked ? Colors.white : null,
      onTap: _toggleDislike,
    ),
    FunctionalButtonItem(
      icon: AppIcons.comment.icon,
      label: _countLabel(post.commentsCount),
      onTap: () {
        AppBottomSheet.show(
          context: context,
          content: Container(child: Text('Comment')),
        );
      },
    ),
    FunctionalButtonItem(icon: AppIcons.send.icon, label: _countLabel(post.sendsCount), onTap: () {}),
    FunctionalButtonItem(icon: AppIcons.bookmark.icon, label: _countLabel(post.savesCount), onTap: () {}),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PostDetailCubit, PostDetailState>(
        builder: (context, state) {
          return switch (state) {
            PostDetailInitial() || PostDetailLoading() => _buildShell(
              post: widget.initialPost,
              body: widget.initialPost != null
                  ? _buildScrollBody(post: widget.initialPost!)
                  : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            PostDetailError(:final message) => AppFunctionalScreen(
              backgroundColor: Colors.white,
              collapsed: _collapsed,
              buttons: [
                FunctionalButtonItem(
                  icon: AppIcons.back.icon,
                  customColor: AppColors.primary,
                  keepWhenCollapsed: true,
                  onTap: () => context.router.maybePop(),
                ),
              ],
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.base(14, color: AppColors.subTextColor),
                      ),
                      const SizedBox(height: 12),
                      AppButton(text: 'Повторить', onTap: _cubit.reload),
                    ],
                  ),
                ),
              ),
            ),
            PostDetailLoaded(:final item, :final isRefreshing) => _buildLoaded(item, isRefreshing),
          };
        },
      ),
    );
  }

  Widget _buildShell({required Widget body, PostModel? post}) {
    return AppFunctionalScreen(
      backgroundColor: Colors.white,
      collapsed: _collapsed,
      buttons: [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          customColor: AppColors.primary,
          keepWhenCollapsed: true,
          onTap: () => context.router.maybePop(),
        ),
        if (post != null) ...[
          FunctionalButtonItem(
            icon: _isLiked ? AppIcons.likeFilled.icon : AppIcons.like.icon,
            label: _countLabel(_getLikesCount(post.likesCount)),
            customColor: _isLiked ? Colors.red : null,
            iconColor: _isLiked ? Colors.white : null,
            textColor: _isLiked ? Colors.white : null,
            onTap: _toggleLike,
          ),
          FunctionalButtonItem(
            icon: _isDisliked ? AppIcons.dislikeFilled.icon : AppIcons.dislike.icon,
            label: _countLabel(_getDislikesCount(post.dislikesCount)),
            customColor: _isDisliked ? Colors.red : null,
            iconColor: _isDisliked ? Colors.white : null,
            textColor: _isDisliked ? Colors.white : null,
            onTap: _toggleDislike,
          ),
          FunctionalButtonItem(
            icon: AppIcons.comment.icon,
            label: _countLabel(post.commentsCount),
            onTap: () {},
          ),
          FunctionalButtonItem(icon: AppIcons.send.icon, label: _countLabel(post.sendsCount), onTap: () {}),
          FunctionalButtonItem(
            icon: AppIcons.bookmark.icon,
            label: _countLabel(post.savesCount),
            onTap: () {},
          ),
        ],
      ],
      body: body,
    );
  }

  Widget _buildCover(String postId, PostModel post) {
    return GestureDetector(
      onTap: _handleTap, // Отлавливаем все одиночные клики для ручного подсчета
      child: Stack(
        alignment: Alignment.center,
        children: [
          PostCoverHero(
            postId: postId,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: SizedBox(
                width: double.infinity,
                child: PostMediaGallery(media: post.sortedMedia),
              ),
            ),
          ),
          // Анимированная иконка, которая взлетает при дабл/трипл тапе
          if (_overlayIcon != null)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(_overlayIcon, size: 110, color: _overlayIconColor),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScrollBody({required PostModel post, PostFeedItem? item, bool isRefreshing = false}) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (isRefreshing)
          const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2, color: AppColors.primary)),
        SliverToBoxAdapter(child: _buildCover(widget.postId, post)),
        if (item != null)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: _buildInfoContent(item),
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: AppFunctionalScreen.scrollBottomClearance(context))),
      ],
    );
  }

  Widget _buildLoaded(PostFeedItem item, bool isRefreshing) {
    final post = item.post;
    return AppFunctionalScreen(
      backgroundColor: Colors.white,
      collapsed: _collapsed,
      buttons: _buttons(post, item),
      body: _buildScrollBody(post: post, item: item, isRefreshing: isRefreshing),
    );
  }

  Widget _buildInfoContent(PostFeedItem item) {
    final post = item.post;
    final username = item.authorUsername?.trim();
    final avatarUrl = item.authorAvatarUrl?.trim();
    final title = post.title?.trim();
    final description = post.description?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceSoft,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: AppColors.iconMuted, size: 22)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username ?? 'noName',
                    style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(post.createdAt),
                    style: AppTextStyle.base(12, color: AppColors.subTextColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            AppButton(text: '   Подписаться   ', onTap: () {}),
          ],
        ),
        if (title != null && title.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTextStyle.base(24, color: AppColors.textColor, fontWeight: FontWeight.w800),
          ),
        ],
        if (description != null && description.isNotEmpty) ...[
          SizedBox(height: title != null && title.isNotEmpty ? 10 : 18),
          Text(
            description,
            style: AppTextStyle.base(
              15,
              color: AppColors.subTextColor,
              fontWeight: FontWeight.w400,
              height: 1.55,
            ),
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }
}
