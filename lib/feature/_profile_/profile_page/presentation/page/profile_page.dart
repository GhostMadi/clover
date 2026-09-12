import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_state.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_cluster_/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/cluster_list_refresh.dart';
import 'package:clover/feature/_cluster_/cluster/presentation/cubit/clusters_list_cubit.dart';
import 'package:clover/feature/_cluster_/cluster_create/presentation/cubit/cluster_create_upload_cubit.dart';
import 'package:clover/feature/_cluster_/cluster_create/presentation/cubit/cluster_create_upload_state.dart';
import 'package:clover/feature/_post_/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/_post_/post_create/presentation/cubit/post_create_upload_cubit.dart';
import 'package:clover/feature/_post_/post_create/presentation/cubit/post_create_upload_state.dart';
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
  late final AttendanceContextStore _attendanceStore;

  @override
  void initState() {
    super.initState();
    _attendanceStore = sl<AttendanceContextStore>();
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid != null && uid.isNotEmpty) {
      unawaited(_attendanceStore.hydrate(uid, force: true));
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
          const _ProfileServiceShortcutsBlock(),
        ],
      ),
    );
  }
}

/// Две линии быстрых входов: верх — «мне дают», низ — «я веду сервис».
///
/// В линии ≤2 → иконка+текст; ≥3 → только иконка.
class _ProfileServiceShortcutsBlock extends StatelessWidget {
  const _ProfileServiceShortcutsBlock();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final profile = profileState.mapOrNull(loaded: (s) => s.profile);
        final showBooking = profile?.hasBookingTag ?? false;
        final showBookingCalendar = profile?.hasBookingCalendarTag ?? false;
        final showAdminAttendance = profile?.hasAttendanceTag ?? false;
        final showWorkerAttendance = profile?.hasAttendanceWorkTag ?? false;
        final showResources = profile?.hasResourcesTag ?? false;

        final bookingAccent = bookingServiceAccent(context.colors);
        final attendanceAccent = attendanceServiceAccent(context.colors);
        final resourcesAccent = context.colors.serviceAccent(kResourcesService);

        final workerSpecs = <_ProfileShortcutSpec>[
          if (showBookingCalendar)
            _ProfileShortcutSpec(
              label: 'Календарь',
              icon: AppIcons.calendarToday.icon,
              iconColor: bookingAccent.icon,
              builder: (child) => AppOutlinedButton(
                text: 'Календарь',
                service: kBookingService,
                isExpanded: true,
                onTap: () => context.router.push(const BookingCalendarRoute()),
                child: child,
              ),
            ),
          if (showWorkerAttendance)
            _ProfileShortcutSpec(
              label: 'Посещаемость',
              icon: AppIcons.schedule.icon,
              iconColor: attendanceAccent.icon,
              builder: (child) => AppOutlinedButton(
                text: 'Посещаемость',
                service: kAttendanceService,
                isExpanded: true,
                onTap: () => context.router.push(const AttendanceWorkerHubRoute()),
                child: child,
              ),
            ),
        ];

        final adminSpecs = <_ProfileShortcutSpec>[
          if (showBooking)
            _ProfileShortcutSpec(
              label: 'Запись',
              icon: AppIcons.calendarMonth.icon,
              iconColor: bookingAccent.ctaForeground,
              builder: (child) => BookingPrimaryButton(
                text: 'Запись',
                isExpanded: true,
                onTap: () => context.router.push(const SettingsBookingRoute()),
                child: child,
              ),
            ),
          if (showAdminAttendance)
            _ProfileShortcutSpec(
              label: 'Управление',
              icon: AppIcons.schedule.icon,
              iconColor: attendanceAccent.ctaForeground,
              builder: (child) => AttendancePrimaryButton(
                text: 'Управление',
                isExpanded: true,
                onTap: () => context.router.push(const AttendanceHubRoute()),
                child: child,
              ),
            ),
          if (showResources)
            _ProfileShortcutSpec(
              label: 'Ресурсы',
              icon: AppIcons.inventory.icon,
              iconColor: resourcesAccent.ctaForeground,
              builder: (child) => AppButton(
                text: 'Ресурсы',
                service: kResourcesService,
                isExpanded: true,
                onTap: () => context.router.push(const SettingsResourcesRoute()),
                child: child,
              ),
            ),
        ];

        if (workerSpecs.isEmpty && adminSpecs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              if (workerSpecs.isNotEmpty) _ProfileShortcutLine(specs: workerSpecs),
              if (workerSpecs.isNotEmpty && adminSpecs.isNotEmpty) const SizedBox(height: 10),
              if (adminSpecs.isNotEmpty) _ProfileShortcutLine(specs: adminSpecs),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileShortcutLine extends StatelessWidget {
  const _ProfileShortcutLine({required this.specs});

  final List<_ProfileShortcutSpec> specs;

  @override
  Widget build(BuildContext context) {
    final iconOnly = specs.length >= 3;
    return Row(
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: specs[i].builder(
              _ProfileShortcutContent(
                icon: specs[i].icon,
                label: specs[i].label,
                color: specs[i].iconColor,
                iconOnly: iconOnly,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileShortcutSpec {
  const _ProfileShortcutSpec({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget Function(Widget child) builder;
}

class _ProfileShortcutContent extends StatelessWidget {
  const _ProfileShortcutContent({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconOnly,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (iconOnly) {
      return Tooltip(
        message: label,
        child: Icon(icon, color: color, size: 22),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.base(15, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2),
          ),
        ),
      ],
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
