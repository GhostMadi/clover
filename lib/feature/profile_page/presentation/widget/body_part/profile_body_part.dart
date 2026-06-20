import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/settings_filter/presentation/profile/widget/profile_feed_filter_section.dart';
import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/post/presentation/widget/post_feed_shimmer.dart';
import 'package:clover/feature/post/presentation/widget/post_feed_view.dart';
import 'package:clover/feature/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Нижняя часть профиля: табы и контент (скролл страницы).
class ProfileBodyPart extends StatefulWidget {
  const ProfileBodyPart({
    super.key,
    this.ownerId,
    this.authorProfile,
    required this.publicationsFeedCubit,
    required this.markerFeedCubit,
  });

  /// `null` — шиммер-заглушка.
  final String? ownerId;
  final ProfileNewModel? authorProfile;
  final PostFeedCubit publicationsFeedCubit;
  final PostFeedCubit markerFeedCubit;

  @override
  State<ProfileBodyPart> createState() => _ProfileBodyPartState();
}

class _ProfileBodyPartState extends State<ProfileBodyPart> {
  int _tabIndex = 0;
  Set<String> _selectedFilterValues = const {};

  static const _tabs = ['Публикации', 'Ивенты'];

  void _openPost(BuildContext context, PostFeedItem item) {
    String? authorUsername = item.authorUsername?.trim();
    if (authorUsername != null && authorUsername.isEmpty) authorUsername = null;
    String? authorAvatarUrl = item.authorAvatarUrl?.trim();
    if (authorAvatarUrl != null && authorAvatarUrl.isEmpty) authorAvatarUrl = null;

    ProfileNewModel? profile = widget.authorProfile;
    if (profile == null) {
      try {
        profile = context.read<ProfileCubit>().state.mapOrNull(loaded: (s) => s.profile);
      } catch (_) {}
    }
    if (profile != null && item.post.userId.trim() == profile.id.trim()) {
      final username = profile.username?.trim();
      if (username != null && username.isNotEmpty) {
        authorUsername = username;
      }
      final avatarUrl = profile.avatarUrl?.trim();
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        authorAvatarUrl = avatarUrl;
      }
    } else if (profile != null) {
      authorUsername ??= profile.username?.trim();
      authorAvatarUrl ??= profile.avatarUrl?.trim();
    }

    context.router.root.push(
      PostRoute(
        postId: item.post.id,
        initialPost: item.post,
        initialMarker: item.marker,
        initialMyReaction: item.myReaction,
        initialAuthorUsername: authorUsername,
        initialAuthorAvatarUrl: authorAvatarUrl,
      ),
    );
  }

  void _onFilterSelectionChanged(Set<String> values) {
    setState(() => _selectedFilterValues = values);

    final ownerId = widget.ownerId?.trim();
    if (ownerId == null || ownerId.isEmpty) return;

    widget.publicationsFeedCubit.load(ownerId, filterSelectionKeys: values);
    widget.markerFeedCubit.load(
      ownerId,
      onlyWithMarker: true,
      filterSelectionKeys: values,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasOwner = widget.ownerId != null && widget.ownerId!.trim().isNotEmpty;
    final hasFilters = _resolveHasFilters(context);

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
          ProfileFeedFilterSection(
            tabs: _tabs,
            currentTabIndex: _tabIndex,
            onTabChanged: (i) => setState(() => _tabIndex = i),
            hasFilters: hasFilters,
            profileId: widget.ownerId,
            selectedValues: _selectedFilterValues,
            onSelectedValuesChanged: _onFilterSelectionChanged,
          ),
          SizedBox(height: context.heightByContext(16)),
          Offstage(
            offstage: _tabIndex != 0,
            child: BlocProvider.value(
              value: widget.publicationsFeedCubit,
              child: _ProfilePublicationsTab(
                key: const ValueKey('profile_tab_publications'),
                hasOwner: hasOwner,
                onPostTap: (item) => _openPost(context, item),
              ),
            ),
          ),
          Offstage(
            offstage: _tabIndex != 1,
            child: BlocProvider.value(
              value: widget.markerFeedCubit,
              child: _ProfileMarkersTab(
                key: const ValueKey('profile_tab_markers'),
                hasOwner: hasOwner,
                onPostTap: (item) => _openPost(context, item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _resolveHasFilters(BuildContext context) {
    final fromAuthor = widget.authorProfile?.hasFilters;
    if (fromAuthor != null) return fromAuthor;

    try {
      return context.select<ProfileCubit, bool>(
        (cubit) => cubit.state.mapOrNull(loaded: (s) => s.profile.hasFilters) ?? false,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Вкладка «Публикации» — посты без маркера.
class _ProfilePublicationsTab extends StatelessWidget {
  const _ProfilePublicationsTab({super.key, required this.hasOwner, required this.onPostTap});

  final bool hasOwner;
  final ValueChanged<PostFeedItem> onPostTap;

  @override
  Widget build(BuildContext context) {
    return hasOwner ? PostFeedView(onPostTap: onPostTap) : const PostFeedShimmer(tileCount: 6);
  }
}

/// Вкладка «Маркеры» — посты с привязанным маркером.
class _ProfileMarkersTab extends StatelessWidget {
  const _ProfileMarkersTab({super.key, required this.hasOwner, required this.onPostTap});

  final bool hasOwner;
  final ValueChanged<PostFeedItem> onPostTap;

  @override
  Widget build(BuildContext context) {
    return hasOwner
        ? PostFeedView(onPostTap: onPostTap, emptyMessage: 'Пусто — маркеров нет')
        : const PostFeedShimmer(tileCount: 6);
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
