import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/feature/archive/presentation/widget/archive_post_grid_shimmer.dart';
import 'package:clover/feature/archive/post_archive/presentation/cubit/post_archive_cubit.dart';
import 'package:clover/feature/post/data/models/post_archive_context.dart';
import 'package:clover/feature/post/presentation/widget/post_grid.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@RoutePage()
class PostArchivePage extends StatefulWidget {
  const PostArchivePage({super.key});

  @override
  State<PostArchivePage> createState() => _PostArchivePageState();
}

class _PostArchivePageState extends State<PostArchivePage> {
  late final PostArchiveCubit _cubit;
  final String? _uid = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cubit = sl<PostArchiveCubit>();
    final uid = _uid?.trim();
    if (uid != null && uid.isNotEmpty) {
      _cubit.load(uid);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    final uid = _uid?.trim();
    if (uid == null || uid.isEmpty) return;
    await _cubit.load(uid);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: SettingsScreenShell(
        title: 'Архив публикаций',
        body: AppRefresh(
          onRefresh: _refresh,
          child: BlocBuilder<PostArchiveCubit, PostArchiveState>(
            builder: (context, state) {
              return switch (state) {
                PostArchiveInitial() || PostArchiveLoading() => const ArchivePostGridShimmer(),
                PostArchiveError(:final message) => _ArchiveError(message: message, onRetry: _refresh),
                PostArchiveLoaded(:final posts) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(3, 8, 3, SettingsScreenShell.scrollBottomGap(context)),
                  child: PostGrid(
                    posts: posts,
                    emptyMessage: 'Архив публикаций пуст',
                    onPostTap: (post) async {
                      final refreshed = await context.router.push<bool>(
                        PostRoute(
                          postId: post.id,
                          initialPost: post,
                          archiveContext: PostArchiveContext.publication,
                        ),
                      );
                      if (refreshed == true && mounted) await _refresh();
                    },
                  ),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _ArchiveError extends StatelessWidget {
  const _ArchiveError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.subTextColor)),
          const SizedBox(height: 12),
          AppButton(text: 'Повторить', onTap: onRetry),
        ],
      ),
    );
  }
}
