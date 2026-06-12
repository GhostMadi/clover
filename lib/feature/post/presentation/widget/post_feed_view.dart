import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:clover/feature/post/presentation/cubit/post_feed_cubit.dart';
import 'package:clover/feature/post/presentation/widget/post_feed_shimmer.dart';
import 'package:clover/feature/post/presentation/widget/post_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Сетка постов из [PostFeedCubit] (local → remote).
class PostFeedView extends StatelessWidget {
  const PostFeedView({super.key, this.onPostTap});

  final ValueChanged<PostModel>? onPostTap;

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
          PostFeedError(:final message) => _PostFeedError(
            message: message,
            onRetry: () => context.read<PostFeedCubit>().reload(),
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
                  const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
                PostGrid(
                  posts: posts,
                  savedByPostId: savedByPostId,
                  onPostTap: onPostTap,
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

class _PostFeedError extends StatelessWidget {
  const _PostFeedError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: AppTextStyle.base(13, color: AppColors.subTextColor)),
          const SizedBox(height: 8),
          AppButton(text: 'Повторить', onTap: onRetry),
        ],
      ),
    );
  }
}
