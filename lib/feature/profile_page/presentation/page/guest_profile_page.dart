import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/cluster/presentation/cubit/clusters_list_cubit.dart';
import 'package:clover/feature/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/profile_page/presentation/cubit/guest_profile_cubit.dart';
import 'package:clover/feature/profile_page/presentation/widget/body_part/profile_body_part.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/parts/profile_header_from_profile.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/profile_header_section.dart';
import 'package:clover/feature/profile_page/presentation/widget/middle_part/profile_middle_part.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class GuestProfilePage extends StatefulWidget {
  const GuestProfilePage({super.key, required this.userId});

  final String userId;

  @override
  State<GuestProfilePage> createState() => _GuestProfilePageState();
}

class _GuestProfilePageState extends State<GuestProfilePage> {
  late final GuestProfileCubit _cubit;
  late final ClustersListCubit _clustersCubit;
  late final PostFeedCubit _postFeedCubit;
  String? _selectedClusterId;

  String get _userId => widget.userId.trim();

  @override
  void initState() {
    super.initState();
    _cubit = sl<GuestProfileCubit>()..load(_userId);
    _clustersCubit = sl<ClustersListCubit>()..load(_userId);
    _postFeedCubit = sl<PostFeedCubit>()..load(_userId, excludeWithMarker: false);
  }

  @override
  void dispose() {
    _cubit.close();
    _clustersCubit.close();
    _postFeedCubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _cubit.refresh(),
      _clustersCubit.load(_userId, silent: true),
      _postFeedCubit.refresh(),
    ]);
  }

  void _onClusterTap(ClusterModel cluster) {
    final next = _selectedClusterId == cluster.id ? null : cluster.id;
    setState(() => _selectedClusterId = next);
    _postFeedCubit.load(_userId, clusterId: next, excludeWithMarker: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AppFunctionalScreen(
        collapsed: true,
        collapsedBarWidthPerButton: 150,
        buttons: [
          FunctionalButtonItem(
            icon: AppIcons.back.icon,
            keepWhenCollapsed: true,
            customColor: AppColors.primary,
            onTap: () => context.router.maybePop(),
          ),
        ],
        body: SafeArea(
          bottom: false,
          child: MultiBlocProvider(
            providers: [BlocProvider.value(value: _clustersCubit)],
            child: AppRefresh(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GuestHeaderBlock(onRetry: () => _cubit.load(_userId)),
                    _GuestFollowActions(cubit: _cubit),
                    ProfileMiddlePart(
                      ownerId: _userId,
                      selectedClusterId: _selectedClusterId,
                      onClusterTap: _onClusterTap,
                      readOnly: true,
                    ),
                    BlocBuilder<GuestProfileCubit, GuestProfileState>(
                      buildWhen: (prev, next) {
                        final prevProfile = prev.mapOrNull(loaded: (s) => s.profile);
                        final nextProfile = next.mapOrNull(loaded: (s) => s.profile);
                        if (prevProfile?.id != nextProfile?.id) return true;
                        if (prevProfile?.hasFilters != nextProfile?.hasFilters) return true;
                        return prev.runtimeType != next.runtimeType;
                      },
                      builder: (context, profileState) {
                        final profile = profileState.mapOrNull(loaded: (s) => s.profile);
                        return ProfileBodyPart(
                          ownerId: _userId,
                          authorProfile: profile,
                          publicationsFeedCubit: _postFeedCubit,
                        );
                      },
                    ),
                    SizedBox(height: AppFunctionalScreen.scrollBottomClearance(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestHeaderBlock extends StatelessWidget {
  const _GuestHeaderBlock({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuestProfileCubit, GuestProfileState>(
      builder: (context, state) {
        return state.when(
          initial: () => const ProfileHeaderSection.loading(),
          loading: () => const ProfileHeaderSection.loading(),
          loaded: (profile, _, __) => ProfileHeaderFromProfile(profile: profile),
          error: (message) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GuestProfileErrorTop(message: message, onRetry: onRetry),
              const ProfileHeaderSection.loading(),
            ],
          ),
        );
      },
    );
  }
}

class _GuestFollowActions extends StatefulWidget {
  const _GuestFollowActions({required this.cubit});

  final GuestProfileCubit cubit;

  @override
  State<_GuestFollowActions> createState() => _GuestFollowActionsState();
}

class _GuestFollowActionsState extends State<_GuestFollowActions> {
  bool _isOpeningChat = false;

  GuestProfileCubit get cubit => widget.cubit;

  Future<void> _openChat(String userId, String username) async {
    if (_isOpeningChat) return;

    setState(() => _isOpeningChat = true);
    try {
      final conversationId = await sl<ChatRepository>().createDm(userId);
      if (!mounted) return;
      await context.router.push(ChatRoute(chatId: conversationId, username: username));
    } catch (error) {
      if (!mounted) return;
      final message = error is ChatRepositoryException ? error.message : 'Не удалось открыть чат';
      AppSnackBar.show(context, message: message, kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!cubit.canToggleFollow) return const SizedBox.shrink();

    return BlocBuilder<GuestProfileCubit, GuestProfileState>(
      buildWhen: (prev, next) {
        final prevLoaded = prev.mapOrNull(loaded: (s) => s);
        final nextLoaded = next.mapOrNull(loaded: (s) => s);
        if (prevLoaded == null || nextLoaded == null) {
          return prev.runtimeType != next.runtimeType;
        }
        return prevLoaded.isFollowing != nextLoaded.isFollowing ||
            prevLoaded.isFollowUpdating != nextLoaded.isFollowUpdating;
      },
      builder: (context, state) {
        final loaded = state.mapOrNull(loaded: (s) => s);
        if (loaded == null) return const SizedBox.shrink();

        final username = loaded.profile.username?.trim();
        final displayName = username?.isNotEmpty == true ? username! : 'user';
        final hostLabel = loaded.profile.fullName?.trim().isNotEmpty == true
            ? loaded.profile.fullName!.trim()
            : displayName;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              loaded.isFollowing
                  ? Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: AppOutlinedButton(
                            text: '',
                            isLoading: loaded.isFollowUpdating,
                            onTap: cubit.toggleFollow,
                            child: Icon(Icons.person_remove_alt_1_rounded, color: AppColors.textColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: 'Сообщения',
                            isExpanded: true,
                            isLoading: _isOpeningChat,
                            onTap: _isOpeningChat ? null : () => _openChat(loaded.profile.id, displayName),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Подписаться',
                            isExpanded: true,
                            isLoading: loaded.isFollowUpdating,
                            onTap: cubit.toggleFollow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 56,
                          child: AppOutlinedButton(
                            text: ' ',
                            isLoading: _isOpeningChat,
                            onTap: _isOpeningChat ? null : () => _openChat(loaded.profile.id, displayName),
                            child: Icon(AppIcons.chat.icon, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 10),
              if (loaded.profile.hasBookingTag)
                AppButton(
                  text: 'Записаться',
                  isExpanded: true,
                  onTap: () => context.router.push(
                    BookingClientRoute(hostId: loaded.profile.id, hostDisplayName: hostLabel),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GuestProfileErrorTop extends StatelessWidget {
  const _GuestProfileErrorTop({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.subTextColor, fontSize: 13),
          ),
          const SizedBox(height: 8),
          AppButton(text: 'Повторить', onTap: onRetry),
        ],
      ),
    );
  }
}
