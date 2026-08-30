import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/chat_page/data/models/chat_message_post_ref.dart';
import 'package:clover/feature/post/data/models/post_model.dart';
import 'package:clover/feature/post/data/repository/post_repository.dart';
import 'package:clover/feature/post/presentation/widget/post_image_tile.dart';
import 'package:flutter/material.dart';

/// Компактное превью поста внутри пузыря чата; по тапу открывает [PostRoute].
class ChatPostRefPreview extends StatefulWidget {
  const ChatPostRefPreview({
    super.key,
    required this.postRef,
  });

  final ChatMessagePostRef postRef;

  static const double width = 220;

  @override
  State<ChatPostRefPreview> createState() => _ChatPostRefPreviewState();
}

class _ChatPostRefPreviewState extends State<ChatPostRefPreview> {
  PostModel? _post;
  bool _loadingRemote = false;

  String get _postId => widget.postRef.postId;

  @override
  void initState() {
    super.initState();
    _post = sl<PostRepository>().getCachedPostById(_postId);
    if (_needsRemoteLoad) _loadRemote();
  }

  @override
  void didUpdateWidget(covariant ChatPostRefPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postRef.postId != widget.postRef.postId) {
      _post = sl<PostRepository>().getCachedPostById(_postId);
      if (_needsRemoteLoad) _loadRemote();
    }
  }

  bool get _needsRemoteLoad {
    final ref = widget.postRef;
    if (ref.coverUrl?.isNotEmpty == true && ref.title?.isNotEmpty == true) return false;
    if (_post != null) return false;
    return true;
  }

  Future<void> _loadRemote() async {
    if (!mounted) return;
    setState(() => _loadingRemote = true);
    final item = await sl<PostRepository>().getPostEnriched(_postId);
    if (!mounted) return;
    setState(() {
      _post = item?.post ?? _post;
      _loadingRemote = false;
    });
  }

  void _openPost() {
    context.router.push(
      PostRoute(
        postId: _postId,
        initialPost: _post,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPost,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: ChatPostRefPreview.width,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final ref = widget.postRef;
    final post = _post;
    final coverUrl = ref.coverUrl ?? post?.coverMedia?.previewImageUrl;
    final title = ref.title ?? post?.title?.trim();

    if (coverUrl == null && title == null && _loadingRemote) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (coverUrl == null && title == null && post == null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Пост недоступен',
          style: AppTextStyle.base(13, color: AppColors.subTextColor),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: coverUrl == null
              ? const PostImagePlaceholder()
              : PostImageTile(
                  imageUrl: coverUrl,
                  borderRadius: 0,
                ),
        ),
        if (_loadingRemote)
          const LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: AppColors.surfaceSoft,
            color: AppColors.primary,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Text(
            title?.isNotEmpty == true ? title! : 'Пост',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.base(13, color: AppColors.textColor, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Пузырь с шарингом поста; при отсутствии post_ref догружает enriched-сообщение.
class ChatPostShareBubble extends StatefulWidget {
  const ChatPostShareBubble({
    super.key,
    required this.message,
    required this.background,
    required this.textColor,
    required this.metaColor,
    required this.borderRadius,
    required this.timeLabel,
    required this.isMine,
    required this.bubbleDecoration,
    required this.timeRow,
  });

  final ChatMessage message;
  final Color background;
  final Color textColor;
  final Color metaColor;
  final BorderRadius borderRadius;
  final String timeLabel;
  final bool isMine;
  final BoxDecoration Function(Color background, BorderRadius borderRadius, bool isMine) bubbleDecoration;
  final Widget Function(String timeLabel, Color metaColor, bool isMine, ChatMessage message) timeRow;

  @override
  State<ChatPostShareBubble> createState() => _ChatPostShareBubbleState();
}

class _ChatPostShareBubbleState extends State<ChatPostShareBubble> {
  ChatMessage? _resolved;

  ChatMessage get _message => _resolved ?? widget.message;

  @override
  void initState() {
    super.initState();
    _repairIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ChatPostShareBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.postRef?.postId != widget.message.postRef?.postId) {
      _resolved = null;
      _repairIfNeeded();
    }
  }

  Future<void> _repairIfNeeded() async {
    final message = widget.message;
    if (message.hasPostPreview || message.isPending) return;

    final enriched = await sl<ChatRepository>().getMessageEnriched(message.id);
    if (!mounted || enriched == null || !enriched.hasPostPreview) return;

    setState(() => _resolved = enriched);
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    final caption = message.text.trim();
    final postRef = message.postRef;

    return DecoratedBox(
      decoration: widget.bubbleDecoration(widget.background, widget.borderRadius, widget.isMine),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (caption.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  caption,
                  style: AppTextStyle.base(15, color: widget.textColor, height: 1.35),
                ),
              ),
            ],
            if (postRef != null)
              ChatPostRefPreview(postRef: postRef)
            else
              const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            const SizedBox(height: 6),
            widget.timeRow(widget.timeLabel, widget.metaColor, widget.isMine, message),
          ],
        ),
      ),
    );
  }
}
