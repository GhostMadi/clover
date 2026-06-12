import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/cluster/presentation/cubit/clusters_list_cubit.dart';
import 'package:clover/feature/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/post_create/presentation/cubit/post_create_upload_cubit.dart';
import 'package:clover/feature/post_create/presentation/cubit/post_create_upload_state.dart';
import 'package:clover/feature/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:clover/feature/profile_page/presentation/widget/body_part/profile_body_part.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/parts/profile_header_from_profile.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/profile_header_section.dart';
import 'package:clover/feature/profile_page/presentation/widget/middle_part/profile_middle_part.dart';
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
  late final PostCreateUploadCubit _postCreateUploadCubit;
  final String? _uid = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProfileCubit>()..load();
    _clustersCubit = sl<ClustersListCubit>()..load(_uid ?? '');
    _postFeedCubit = sl<PostFeedCubit>();
    _postCreateUploadCubit = sl<PostCreateUploadCubit>();
    final uid = _uid?.trim();
    if (uid != null && uid.isNotEmpty) {
      _postFeedCubit.load(uid);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    // _clustersCubit.close();
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
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _clustersCubit),
        BlocProvider.value(value: _postFeedCubit),
        BlocProvider.value(value: _postCreateUploadCubit),
      ],
      child: BlocListener<PostCreateUploadCubit, PostCreateUploadState>(
        listenWhen: (previous, current) => current is PostCreateUploadSuccess,
        listener: (context, state) {
          final uid = _uid?.trim();
          if (uid != null && uid.isNotEmpty) {
            context.read<PostFeedCubit>().refresh();
          }
        },
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
                    const _ProfileHeaderBlock(),
                    const _ProfileNewActions(),
                    ProfileMiddlePart(ownerId: _uid),

                    ProfileBodyPart(ownerId: _uid),
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
      child: Row(
        children: [
          Expanded(
            child: AppOutlinedButton(text: 'Редактировать профиль', onTap: () {}, isExpanded: true),
          ),
          const SizedBox(width: 8),
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
                  ],
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            text: '',
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.settings_outlined, color: Colors.white, size: 22),
            ),
          ),
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
      buildWhen: (prev, next) {
        final prevErr = prev.mapOrNull(error: (e) => e.message);
        final nextErr = next.mapOrNull(error: (e) => e.message);
        if (prevErr != nextErr) return true;
        final prevId = prev.mapOrNull(loaded: (e) => e.profile.id);
        final nextId = next.mapOrNull(loaded: (e) => e.profile.id);
        if (prevId != nextId) return true;
        return prev.runtimeType != next.runtimeType;
      },
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
