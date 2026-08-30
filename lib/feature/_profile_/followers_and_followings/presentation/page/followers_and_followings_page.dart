import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_profile_/followers_and_followings/data/models/follow_profile_row.dart';
import 'package:clover/feature/_profile_/followers_and_followings/presentation/cubit/followers_and_followings_cubit.dart';
import 'package:clover/feature/_profile_/followers_and_followings/presentation/widget/follow_profile_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _followListTabs = ['Подписки', 'Подписчики'];

@RoutePage()
class FollowersAndFollowingsPage extends StatefulWidget {
  const FollowersAndFollowingsPage({
    super.key,
    required this.profileId,
    this.username,
    this.initialTabIndex = 0,
  });

  final String profileId;
  final String? username;
  final int initialTabIndex;

  @override
  State<FollowersAndFollowingsPage> createState() => _FollowersAndFollowingsPageState();
}

class _FollowersAndFollowingsPageState extends State<FollowersAndFollowingsPage> {
  late final FollowersAndFollowingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<FollowersAndFollowingsCubit>()
      ..load(widget.profileId, initialTabIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String get _pageTitle {
    final username = widget.username?.trim();
    if (username != null && username.isNotEmpty) return '@$username';
    return 'Подписки';
  }

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id.trim();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: SettingsScreenShell(
        title: _pageTitle,
        body: BlocBuilder<FollowersAndFollowingsCubit, FollowersAndFollowingsState>(
          builder: (context, state) {
            return switch (state) {
              FollowersAndFollowingsInitial() => const Center(child: CircularProgressIndicator()),
              FollowersAndFollowingsError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.base(14, color: AppColors.subTextColor),
                  ),
                ),
              ),
              FollowersAndFollowingsLoaded() => _LoadedBody(
                state: state,
                currentUserId: _currentUserId,
                onRefresh: _cubit.refresh,
                onTabChanged: _cubit.setTab,
                onToggleFollow: (row, isFollowingTab) {
                  _cubit.toggleFollow(row.profileId, isFollowingTab: isFollowingTab);
                },
              ),
            };
          },
        ),
      ),
    );
  }
}

class _LoadedBody extends StatefulWidget {
  const _LoadedBody({
    required this.state,
    required this.currentUserId,
    required this.onRefresh,
    required this.onTabChanged,
    required this.onToggleFollow,
  });

  final FollowersAndFollowingsLoaded state;
  final String? currentUserId;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onTabChanged;
  final void Function(FollowProfileRow row, bool isFollowingTab) onToggleFollow;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.state.tabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == widget.state.tabIndex) return;
    widget.onTabChanged(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (index == widget.state.tabIndex) return;
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AppTab(
            tabs: _followListTabs,
            currentIndex: widget.state.tabIndex,
            onTabChanged: _onTabTap,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _FollowListTab(
                rows: widget.state.following,
                isLoading: widget.state.followingLoading,
                error: widget.state.followingError,
                emptyMessage: 'Пока нет подписок',
                currentUserId: widget.currentUserId,
                onRefresh: widget.onRefresh,
                onToggleFollow: (row) => widget.onToggleFollow(row, true),
              ),
              _FollowListTab(
                rows: widget.state.followers,
                isLoading: widget.state.followersLoading,
                error: widget.state.followersError,
                emptyMessage: 'Пока нет подписчиков',
                currentUserId: widget.currentUserId,
                onRefresh: widget.onRefresh,
                onToggleFollow: (row) => widget.onToggleFollow(row, false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FollowListTab extends StatelessWidget {
  const _FollowListTab({
    required this.rows,
    required this.isLoading,
    required this.error,
    required this.emptyMessage,
    required this.currentUserId,
    required this.onRefresh,
    required this.onToggleFollow,
  });

  final List<FollowProfileRow> rows;
  final bool isLoading;
  final String? error;
  final String emptyMessage;
  final String? currentUserId;
  final Future<void> Function() onRefresh;
  final ValueChanged<FollowProfileRow> onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return AppRefresh(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 0, 16, SettingsScreenShell.scrollBottomGap(context)),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: AppTextStyle.base(13, color: AppColors.subTextColor),
              ),
            ),
          if (isLoading && rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: AppTextStyle.base(14, color: AppColors.subTextColor),
              ),
            )
          else
            AppTileGroup(
              children: [
                for (final row in rows)
                  FollowProfileTile(
                    row: row,
                    showFollowButton: _shouldShowFollowButton(row),
                    onToggleFollow: _shouldShowFollowButton(row) ? () => onToggleFollow(row) : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  bool _shouldShowFollowButton(FollowProfileRow row) {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) return false;
    return row.profileId != uid;
  }
}
