import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:clover/feature/post/data/repository/post_repository.dart';
import 'package:clover/feature/post/presentation/widget/post_image_tile.dart';
import 'package:flutter/material.dart';

/// Карточка одного поста: мгновенно из memory-кэша, затем remote enriched.
class PostPreviewCard extends StatefulWidget {
  const PostPreviewCard({super.key, required this.postId});

  final String postId;

  @override
  State<PostPreviewCard> createState() => _PostPreviewCardState();
}

class _PostPreviewCardState extends State<PostPreviewCard> {
  PostModel? _post;
  bool _loadingRemote = false;

  @override
  void initState() {
    super.initState();
    _post = sl<PostRepository>().getCachedPostById(widget.postId);
    _loadRemote();
  }

  @override
  void didUpdateWidget(covariant PostPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _post = sl<PostRepository>().getCachedPostById(widget.postId);
      _loadRemote();
    }
  }

  Future<void> _loadRemote() async {
    if (!mounted) return;
    setState(() => _loadingRemote = _post == null);
    final item = await sl<PostRepository>().getPostEnriched(widget.postId);
    if (!mounted) return;
    setState(() {
      _post = item?.post ?? _post;
      _loadingRemote = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final radius = context.widthByContext(18);

    if (post == null && _loadingRemote) {
      return SizedBox(
        height: context.heightByContext(260),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (post == null) {
      return Padding(
        padding: EdgeInsets.all(context.widthByContext(16)),
        child: Text(
          'Пост недоступен',
          style: AppTextStyle.base(context.heightByContext(14), color: AppColors.subTextColor),
        ),
      );
    }

    final cover = post.coverMedia;
    final coverAspect = cover?.aspectRatio ?? PostAspectRatio.square1x1;
    final title = post.title?.trim();
    final desc = post.description?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: coverAspect.ratio,
              child: cover?.previewImageUrl == null
                  ? const PostImagePlaceholder()
                  : PostImageTile(
                      imageUrl: cover!.previewImageUrl,
                      blurHash: cover.blurHash,
                      borderRadius: 0,
                    ),
            ),
            if (_loadingRemote)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.surfaceSoft,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            if (title != null && title.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.widthByContext(14),
                  context.heightByContext(12),
                  context.widthByContext(14),
                  0,
                ),
                child: Text(
                  title,
                  style: AppTextStyle.base(
                    context.heightByContext(16),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textColor,
                  ),
                ),
              ),
            if (desc != null && desc.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.widthByContext(14),
                  context.heightByContext(8),
                  context.widthByContext(14),
                  context.heightByContext(14),
                ),
                child: Text(
                  desc,
                  style: AppTextStyle.base(
                    context.heightByContext(14),
                    height: 1.35,
                    color: AppColors.textColor.withValues(alpha: 0.9),
                  ),
                ),
              )
            else
              SizedBox(height: context.heightByContext(14)),
          ],
        ),
      ),
    );
  }
}
