import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_state.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_cluster_/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/cluster_list_refresh.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/cubit/clusters_list_cubit.dart';
import 'package:clover/feature/_cluster_/cluster_create/presentation/cubit/cluster_create_upload_cubit.dart';
import 'package:clover/feature/_cluster_/cluster_create/presentation/cubit/cluster_create_upload_state.dart';
import 'package:clover/feature/_post_/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/_post_/post_create/presentation/cubit/post_create_upload_cubit.dart';
import 'package:clover/feature/_post_/post_create/presentation/cubit/post_create_upload_state.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/profile_attendance_admin_shortcut_store.dart';
import 'package:clover/feature/_profile_/profile_page/data/profile_booking_shortcut_store.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/body_part/profile_body_part.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/header_part/parts/profile_header_from_profile.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/header_part/profile_header_section.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/middle_part/profile_middle_part.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/profile_cluster_upload_banner.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/profile_post_upload_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileCubit _cubit;
  late final ClustersListCubit _clustersCubit;
  late final PostFeedCubit _postFeedCubit;
  late final PostCreateUploadCubit _postCreateUploadCubit;
  late final ClusterCreateUploadCubit _clusterCreateUploadCubit;
  String? _selectedClusterId;

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProfileCubit>()..load();
    _clustersCubit = sl<ClustersListCubit>()..load(_uid ?? '');
    _postFeedCubit = sl<PostFeedCubit>();
    _postCreateUploadCubit = sl<PostCreateUploadCubit>();
    _clusterCreateUploadCubit = sl<ClusterCreateUploadCubit>();
    final uid = _uid?.trim();
    if (uid != null && uid.isNotEmpty) {
      _postFeedCubit.load(uid, excludeWithMarker: false);
    }
  }

  @override
  void dispose() {
    // ProfileCubit — singleton в GetIt, не закрываем.
    _clustersCubit.close();
    _postFeedCubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final uid = _uid?.trim();
    await Future.wait([
      _cubit.refresh(),
      if (uid != null && uid.isNotEmpty) ...[
        _clustersCubit.load(uid, silent: true),
        _postFeedCubit.refresh(),
      ],
    ]);
    _dismissUploadBannersIfFinished();
  }

  void _dismissUploadBannersIfFinished() {
    final postState = _postCreateUploadCubit.state;
    if (postState is PostCreateUploadSuccess || postState is PostCreateUploadFailure) {
      _postCreateUploadCubit.reset();
    }

    final clusterState = _clusterCreateUploadCubit.state;
    if (clusterState is ClusterCreateUploadSuccess || clusterState is ClusterCreateUploadFailure) {
      _clusterCreateUploadCubit.reset();
    }
  }

  void _onClusterTap(ClusterModel cluster) {
    final next = _selectedClusterId == cluster.id ? null : cluster.id;
    setState(() => _selectedClusterId = next);

    final uid = _uid?.trim();
    if (uid == null || uid.isEmpty) return;
    _postFeedCubit.load(uid, clusterId: next, excludeWithMarker: false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _clustersCubit),
        BlocProvider.value(value: _postCreateUploadCubit),
        BlocProvider.value(value: _clusterCreateUploadCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<PostCreateUploadCubit, PostCreateUploadState>(
            listenWhen: (previous, current) => current is PostCreateUploadSuccess,
            listener: (context, state) {
              final uid = _uid?.trim();
              if (uid != null && uid.isNotEmpty) {
                _postFeedCubit.refresh();
              }
            },
          ),
          BlocListener<ClusterCreateUploadCubit, ClusterCreateUploadState>(
            listenWhen: (previous, current) => current is ClusterCreateUploadSuccess,
            listener: (context, state) {
              final uid = _uid?.trim();
              if (uid != null && uid.isNotEmpty) {
                clusterListRefreshTick.value++;
                _clustersCubit.load(uid, silent: true);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: context.colors.pageBackground,
          body: SafeArea(
            bottom: false,
            child: AppRefresh(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProfilePostUploadBanner(),
                    const ProfileClusterUploadBanner(),
                    const _ProfileHeaderBlock(),
                    const _ProfileNewActions(),

                    ProfileMiddlePart(
                      ownerId: _uid,
                      selectedClusterId: _selectedClusterId,
                      onClusterTap: _onClusterTap,
                    ),

                    ProfileBodyPart(ownerId: _uid, publicationsFeedCubit: _postFeedCubit),
                    SizedBox(height: AppNavBar.scrollBottomClearance(context)),
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

class _ProfileNewActions extends StatefulWidget {
  const _ProfileNewActions();

  @override
  State<_ProfileNewActions> createState() => _ProfileNewActionsState();
}

class _ProfileNewActionsState extends State<_ProfileNewActions> {
  late final ProfileBookingShortcutStore _bookingShortcutStore;
  late final ProfileAttendanceAdminShortcutStore _attendanceAdminShortcutStore;
  late final AttendanceContextStore _attendanceStore;

  @override
  void initState() {
    super.initState();
    _bookingShortcutStore = sl<ProfileBookingShortcutStore>();
    _attendanceAdminShortcutStore = sl<ProfileAttendanceAdminShortcutStore>();
    _attendanceStore = sl<AttendanceContextStore>();
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid != null && uid.isNotEmpty) {
      _bookingShortcutStore.load(uid);
      _attendanceAdminShortcutStore.load(uid);
      unawaited(_attendanceStore.hydrate(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  text: 'Редактировать',
                  onTap: () async {
                    await context.router.push(const EditProfileRoute());
                    await sl<ProfileCubit>().refresh();
                  },
                  isExpanded: true,
                ),
              ),
              SizedBox(width: context.widthByContext(5)),
              AppButton(
                text: '',
                onTap: () {
                  AppBottomSheet.show(
                    context: context,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppTile(
                          icon: AppIcons.add.icon,
                          title: 'Добавить пост',
                          onTap: () {
                            context.router.push(const PostCreateRoute());
                          },
                        ),
                        AppTile(
                          icon: AppIcons.collectionsFilled.icon,
                          title: 'Добавить кластер',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.router.push(const ClusterCreateRoute());
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(AppIcons.add.icon, color: context.colors.textInverse, size: 22),
                ),
              ),
              SizedBox(width: context.widthByContext(5)),
              AppButton(
                text: '',
                onTap: () {
                  context.router.push(const SettingsRoute());
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(AppIcons.settingsOutlined.icon, color: context.colors.textInverse, size: 22),
                ),
              ),
            ],
          ),
          _ProfileServiceShortcutsRow(
            bookingShortcutStore: _bookingShortcutStore,
            attendanceStore: _attendanceStore,
            attendanceAdminShortcutStore: _attendanceAdminShortcutStore,
          ),
        ],
      ),
    );
  }
}

/// «Запись» + «Посещаемость» в одной строке; admin — отдельной строкой ниже.
class _ProfileServiceShortcutsRow extends StatelessWidget {
  const _ProfileServiceShortcutsRow({
    required this.bookingShortcutStore,
    required this.attendanceStore,
    required this.attendanceAdminShortcutStore,
  });

  final ProfileBookingShortcutStore bookingShortcutStore;
  final AttendanceContextStore attendanceStore;
  final ProfileAttendanceAdminShortcutStore attendanceAdminShortcutStore;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: bookingShortcutStore.visible,
      builder: (context, showBooking, _) {
        return ValueListenableBuilder(
          valueListenable: attendanceStore.snapshot,
          builder: (context, attendanceSnap, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: attendanceAdminShortcutStore.visible,
              builder: (context, showAdminShortcut, _) {
                final showWorker = attendanceSnap?.showProfileWorkerButton ?? false;
                final showAdmin = showAdminShortcut && (attendanceSnap?.isAdmin ?? false);
                if (!showBooking && !showWorker && !showAdmin) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBooking || showWorker)
                        Row(
                          children: [
                            if (showBooking)
                              Expanded(
                                child: AppOutlinedButton(
                                  text: 'Запись',
                                  isExpanded: true,
                                  onTap: () => context.router.push(const BookingListRoute()),
                                ),
                              ),
                            if (showBooking && showWorker) const SizedBox(width: 10),
                            if (showWorker)
                              Expanded(
                                child: AppOutlinedButton(
                                  text: 'Посещаемость',
                                  service: kAttendanceService,
                                  isExpanded: true,
                                  onTap: () => context.router.push(const AttendanceWorkerHubRoute()),
                                ),
                              ),
                          ],
                        ),
                      if (showAdmin) ...[
                        if (showBooking || showWorker) const SizedBox(height: 10),
                        AttendancePrimaryButton(
                          text: 'Управление посещаемостью',
                          isExpanded: true,
                          onTap: () => context.router.push(const AttendanceHubRoute()),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Хедер не зависит от загрузки постов/кластеров — только [ProfileNewCubit].
class _ProfileHeaderBlock extends StatelessWidget {
  const _ProfileHeaderBlock();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return state.when(
          initial: () => const ProfileHeaderSection.loading(),
          loading: () => const ProfileHeaderSection.loading(),
          loaded: (profile) => ProfileHeaderFromProfile(profile: profile),
          error: (message) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppState(
                state: AppScreenState.error,
                variant: AppStateVariant.inline,
                errorMessage: message,
                onRetry: () => context.read<ProfileCubit>().load(),
                child: const SizedBox.shrink(),
              ),
              const ProfileHeaderSection.loading(),
            ],
          ),
        );
      },
    );
  }
}

