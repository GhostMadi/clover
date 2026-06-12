import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/post/presentation/widget/post_feed_shimmer.dart';
import 'package:clover/feature/post/presentation/widget/post_feed_view.dart';
import 'package:flutter/material.dart';

/// Нижняя часть профиля: табы и контент (скролл страницы).
class ProfileBodyPart extends StatefulWidget {
  const ProfileBodyPart({super.key, this.ownerId});

  /// `null` — шиммер-заглушка.
  final String? ownerId;

  @override
  State<ProfileBodyPart> createState() => _ProfileBodyPartState();
}

class _ProfileBodyPartState extends State<ProfileBodyPart> {
  int _tabIndex = 0;

  static const _tabs = ['Публикации', 'Маркеры'];

  @override
  Widget build(BuildContext context) {
    final hasOwner = widget.ownerId != null && widget.ownerId!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.widthByContext(3),
        0,
        context.widthByContext(3),
        context.heightByContext(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTab(tabs: _tabs, currentIndex: _tabIndex, onTabChanged: (i) => setState(() => _tabIndex = i)),
          SizedBox(height: context.heightByContext(16)),
          Offstage(
            offstage: _tabIndex != 0,
            child: _ProfilePublicationsTab(
              key: const ValueKey('profile_tab_publications'),
              hasOwner: hasOwner,
            ),
          ),
          Offstage(
            offstage: _tabIndex != 1,
            child: const _ProfileTabEmpty(key: ValueKey('profile_tab_markers')),
          ),
        ],
      ),
    );
  }
}

/// Вкладка «Публикации» — отдельный виджет, чтобы [Offstage] сохранял дерево.
class _ProfilePublicationsTab extends StatelessWidget {
  const _ProfilePublicationsTab({super.key, required this.hasOwner});

  final bool hasOwner;

  @override
  Widget build(BuildContext context) {
    return hasOwner
        ? PostFeedView(
            onPostTap: (post) {
              context.router.root.push(PostRoute(postId: post.id, initialPost: post));
            },
          )
        : const PostFeedShimmer(tileCount: 6);
  }
}

class _ProfileTabEmpty extends StatelessWidget {
  const _ProfileTabEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.heightByContext(280),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.spa_rounded,
              size: context.heightByContext(56),
              color: AppColors.subTextColor.withValues(alpha: 0.65),
            ),
            SizedBox(height: context.heightByContext(16)),
            Text(
              'Пусто — маркеров нет',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(
                context.heightByContext(16),
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Гость без uid — пустая подпись.
class ProfilePostsGuestPlaceholder extends StatelessWidget {
  const ProfilePostsGuestPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.heightByContext(200),
      child: Center(
        child: Text(
          'Войдите, чтобы видеть публикации',
          textAlign: TextAlign.center,
          style: AppTextStyle.base(context.heightByContext(14), color: AppColors.subTextColor),
        ),
      ),
    );
  }
}
