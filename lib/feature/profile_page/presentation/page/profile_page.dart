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
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/cluster/presentation/cluster_list_refresh.dart';
import 'package:clover/feature/cluster/presentation/cubit/clusters_list_cubit.dart';
import 'package:clover/feature/cluster_create/presentation/cubit/cluster_create_upload_cubit.dart';
import 'package:clover/feature/cluster_create/presentation/cubit/cluster_create_upload_state.dart';
import 'package:clover/feature/marker_create/presentation/cubit/marker_create_upload_cubit.dart';
import 'package:clover/feature/marker_create/presentation/cubit/marker_create_upload_state.dart';
import 'package:clover/feature/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/post_create/presentation/cubit/post_create_upload_cubit.dart';
import 'package:clover/feature/post_create/presentation/cubit/post_create_upload_state.dart';
import 'package:clover/feature/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/profile_page/presentation/widget/body_part/profile_body_part.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/parts/profile_header_from_profile.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/profile_header_section.dart';
import 'package:clover/feature/profile_page/presentation/widget/middle_part/profile_middle_part.dart';
import 'package:clover/feature/profile_page/presentation/widget/profile_cluster_upload_banner.dart';
import 'package:clover/feature/profile_page/presentation/widget/profile_marker_upload_banner.dart';
import 'package:clover/feature/profile_page/presentation/widget/profile_post_upload_banner.dart';
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
  late final PostFeedCubit _markerFeedCubit;
  late final PostCreateUploadCubit _postCreateUploadCubit;
  late final MarkerCreateUploadCubit _markerCreateUploadCubit;
  late final ClusterCreateUploadCubit _clusterCreateUploadCubit;
  String? _selectedClusterId;

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProfileCubit>()..load();
    _clustersCubit = sl<ClustersListCubit>()..load(_uid ?? '');
    _postFeedCubit = sl<PostFeedCubit>();
    _markerFeedCubit = sl<PostFeedCubit>();
    _postCreateUploadCubit = sl<PostCreateUploadCubit>();
    _markerCreateUploadCubit = sl<MarkerCreateUploadCubit>();
    _clusterCreateUploadCubit = sl<ClusterCreateUploadCubit>();
    final uid = _uid?.trim();
    if (uid != null && uid.isNotEmpty) {
      _postFeedCubit.load(uid);
      _markerFeedCubit.load(uid, onlyWithMarker: true);
    }
  }

  @override
  void dispose() {
    // ProfileCubit — singleton в GetIt, не закрываем.
    _clustersCubit.close();
    _postFeedCubit.close();
    _markerFeedCubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final uid = _uid?.trim();
    await Future.wait([
      _cubit.refresh(),
      if (uid != null && uid.isNotEmpty) ...[
        _clustersCubit.load(uid, silent: true),
        _postFeedCubit.refresh(),
        _markerFeedCubit.refresh(),
      ],
    ]);
  }

  void _onClusterTap(ClusterModel cluster) {
    final next = _selectedClusterId == cluster.id ? null : cluster.id;
    setState(() => _selectedClusterId = next);

    final uid = _uid?.trim();
    if (uid == null || uid.isEmpty) return;
    _postFeedCubit.load(uid, clusterId: next);
    _markerFeedCubit.load(uid, clusterId: next, onlyWithMarker: true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _clustersCubit),
        BlocProvider.value(value: _postCreateUploadCubit),
        BlocProvider.value(value: _markerCreateUploadCubit),
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
          BlocListener<MarkerCreateUploadCubit, MarkerCreateUploadState>(
            listenWhen: (previous, current) => current is MarkerCreateUploadSuccess,
            listener: (context, state) {
              final uid = _uid?.trim();
              if (uid != null && uid.isNotEmpty) {
                _postFeedCubit.refresh();
                _markerFeedCubit.refresh();
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
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            bottom: false,
            child: AppRefresh(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProfilePostUploadBanner(),
                    const ProfileMarkerUploadBanner(),
                    const ProfileClusterUploadBanner(),
                    const _ProfileHeaderBlock(),
                    const _ProfileNewActions(),

                    ProfileMiddlePart(
                      ownerId: _uid,
                      selectedClusterId: _selectedClusterId,
                      onClusterTap: _onClusterTap,
                    ),

                    ProfileBodyPart(
                      ownerId: _uid,
                      publicationsFeedCubit: _postFeedCubit,
                      markerFeedCubit: _markerFeedCubit,
                    ),
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

class _ProfileNewActions extends StatelessWidget {
  const _ProfileNewActions();

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
                          icon: AppIcons.map.icon,
                          title: 'Добавить маркер',
                          onTap: () {
                            context.router.push(const MarkerCreateRoute());
                          },
                        ),
                        AppTile(
                          icon: Icons.collections,
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.add, color: Colors.white, size: 22),
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
                          icon: Icons.calendar_month_outlined,
                          title: 'Мои бронирования',
                          onTap: () {
                            context.router.push(const MyBookingsRoute());
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.more_horiz, color: Colors.white, size: 22),
                ),
              ),
              SizedBox(width: context.widthByContext(5)),
              AppButton(
                text: '',
                onTap: () {
                  context.router.push(const SettingsRoute());
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightByContext(10)),
        ],
      ),
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
              _ProfileNewErrorTop(message: message, onRetry: () => context.read<ProfileCubit>().load()),
              const ProfileHeaderSection.loading(),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileNewErrorTop extends StatelessWidget {
  const _ProfileNewErrorTop({required this.message, required this.onRetry});

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
