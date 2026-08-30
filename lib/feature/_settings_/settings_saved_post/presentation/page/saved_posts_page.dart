import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/feature/_archive_/shared/presentation/widget/archive_post_grid_shimmer.dart';
import 'package:clover/feature/_post_/post/data/repository/post_repository.dart';
import 'package:clover/feature/_post_/post/data/models/post_model.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_grid.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings_saved_post/presentation/cubit/saved_posts_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({super.key});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  late final SavedPostsCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = sl<SavedPostsCubit>()..load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scrollController.offset >= max - 320) {
      _cubit.loadMore();
    }
  }

  Future<void> _refresh() => _cubit.refresh();

  Map<String, bool> _savedMap(List<PostModel> posts) {
    return {for (final post in posts) post.id: true};
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: SettingsScreenShell(
        title: 'Сохранённые посты',
        body: AppRefresh(
          onRefresh: _refresh,
          child: BlocBuilder<SavedPostsCubit, SavedPostsState>(
            builder: (context, state) {
              return switch (state) {
                SavedPostsInitial() || SavedPostsLoading() => const ArchivePostGridShimmer(),
                SavedPostsError(:final message) => _SavedPostsError(message: message, onRetry: _refresh),
                SavedPostsLoaded(:final posts, :final isLoadingMore) => SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(3, 8, 3, SettingsScreenShell.scrollBottomGap(context)),
                  child: Column(
                    children: [
                      PostGrid(
                        posts: posts,
                        savedByPostId: _savedMap(posts),
                        emptyMessage: 'Сохранённых постов пока нет',
                        onPostTap: (post) async {
                          sl<PostRepository>().cacheMySaved(post.id, true);
                          await context.router.push(
                            PostRoute(
                              postId: post.id,
                              initialPost: post,
                            ),
                          );
                          if (mounted) await _refresh();
                        },
                      ),
                      if (isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
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

class _SavedPostsError extends StatelessWidget {
  const _SavedPostsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.subTextColor)),
          const SizedBox(height: 12),
          AppButton(text: 'Повторить', onTap: onRetry),
        ],
      ),
    );
  }
}
