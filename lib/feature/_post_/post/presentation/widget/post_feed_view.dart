import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_state.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_feed_shimmer.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Сетка постов из [PostFeedCubit] (local → remote).
class PostFeedView extends StatelessWidget {
  const PostFeedView({
    super.key,
    this.onPostTap,
    this.emptyMessage = 'Нет публикаций',
    this.emptySubtitle,
    this.emptyIcon,
    this.onEmptyAction,
    this.emptyActionLabel = 'Создать',
  });

  final ValueChanged<PostFeedItem>? onPostTap;
  final String emptyMessage;
  final String? emptySubtitle;
  final IconData? emptyIcon;
  final VoidCallback? onEmptyAction;
  final String emptyActionLabel;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.maxScrollExtent <= 0) return false;
        final remaining = n.metrics.maxScrollExtent - n.metrics.pixels;
        if (remaining < 600) {
          context.read<PostFeedCubit>().loadMore();
        }
        return false;
      },
      child: BlocBuilder<PostFeedCubit, PostFeedState>(
      builder: (context, state) {
        return switch (state) {
          PostFeedInitial() || PostFeedLoading() => const PostFeedShimmer(),
          PostFeedError(:final message) => AppState(
            state: AppScreenState.error,
            variant: AppStateVariant.inline,
            errorMessage: message,
            onRetry: () => context.read<PostFeedCubit>().reload(),
            child: const SizedBox.shrink(),
          ),
          PostFeedLoaded(
            :final posts,
            :final savedByPostId,
            :final isLoadingMore,
            :final isRefreshing,
          ) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isRefreshing)
                  LinearProgressIndicator(minHeight: 2, color: context.colors.primary),
                PostGrid(
                  posts: posts,
                  savedByPostId: savedByPostId,
                  emptyMessage: emptyMessage,
                  emptySubtitle: emptySubtitle,
                  emptyIcon: emptyIcon,
                  onEmptyAction: onEmptyAction,
                  emptyActionLabel: emptyActionLabel,
                  onPostTap: onPostTap == null
                      ? null
                      : (post) => onPostTap!(context.read<PostFeedCubit>().feedItemFor(post)),
                ),
                if (isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ],
            ),
        };
      },
      ),
    );
  }
}

