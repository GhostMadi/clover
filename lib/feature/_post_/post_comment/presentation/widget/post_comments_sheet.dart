import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_post_/post_comment/presentation/cubit/post_comments_cubit.dart';
import 'package:clover/feature/_post_/post_comment/presentation/widget/post_comment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Шторка комментариев (~70% экрана), стиль Instagram.
abstract final class PostCommentsSheet {
  static Future<int?> show(BuildContext context, {required String postId, int? initialCommentsCount}) async {
    final cubit = sl<PostCommentsCubit>()..load(postId: postId, initialCommentsCount: initialCommentsCount);

    final height = MediaQuery.sizeOf(context).height * 0.7;

    try {
      await AppBottomSheet.show<void>(
        context: context,
        title: 'Комментарии',
        upperCaseTitle: false,
        contentHeight: height,
        expandBody: true,
        contentPadding: EdgeInsets.zero,
        contentBottomSpacing: 0,
        sheetOuterPadding: const EdgeInsets.fromLTRB(12, 100, 12, 12),
        content: _PostCommentsSheetBody(cubit: cubit),
      );
    } finally {
      if (!cubit.isClosed) await cubit.close();
    }

    return cubit.countDirty ? cubit.commentsCount : null;
  }
}

class _PostCommentsSheetBody extends StatefulWidget {
  const _PostCommentsSheetBody({required this.cubit});

  final PostCommentsCubit cubit;

  @override
  State<_PostCommentsSheetBody> createState() => _PostCommentsSheetBodyState();
}

class _PostCommentsSheetBodyState extends State<_PostCommentsSheetBody> {
  late final TextEditingController _inputController;
  late final ScrollController _scrollController;
  bool _submitting = false;

  PostCommentsCubit get _cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scrollController.offset >= max - 200) {
      _cubit.loadMore();
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final text = _inputController.text;
    if (text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      await _cubit.submitComment(text);
      if (!mounted) return;
      _inputController.clear();
      _cubit.setReplyTarget(null);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось отправить комментарий', kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PostCommentsCubit, PostCommentsState>(
        builder: (context, state) {
          final replyTarget = state is PostCommentsLoaded ? state.replyTarget : null;
          final replyUsername = replyTarget == null
              ? null
              : _usernameForComment(state is PostCommentsLoaded ? state : null, replyTarget.id);

          return Column(
            children: [
              Expanded(
                child: switch (state) {
                  PostCommentsInitial() ||
                  PostCommentsLoading() => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  PostCommentsError(:final message) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.base(14, color: context.colors.subTextColor),
                      ),
                    ),
                  ),
                  PostCommentsLoaded(:final threads, :final isLoadingMore, :final isFromCache) => Column(
                    children: [
                      if (isFromCache)
                        LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: context.colors.surfaceSoft,
                          color: context.colors.primary,
                        ),
                      Expanded(
                        child: threads.isEmpty
                            ? Center(
                                child: Text(
                                  'Комментариев пока нет.\nБудьте первым!',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.4),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                itemCount: threads.length + (isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= threads.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    );
                                  }

                                  final thread = threads[index];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      PostCommentTile(
                                        item: thread.root,
                                        onLikeTap: () => _cubit.toggleLike(thread.root),
                                        onReplyTap: () => _cubit.setReplyTarget(thread.root.comment),
                                      ),
                                      PostCommentRepliesToggle(
                                        repliesCount: thread.root.comment.repliesCount,
                                        expanded: thread.repliesExpanded,
                                        loading: thread.repliesLoading,
                                        onTap: () => _cubit.toggleReplies(thread.root.comment.id),
                                      ),
                                      if (thread.repliesExpanded)
                                        for (final reply in thread.replies)
                                          PostCommentTile(
                                            item: reply,
                                            dense: true,
                                            onLikeTap: () => _cubit.toggleLike(reply),
                                            onReplyTap: () => _cubit.setReplyTarget(reply.comment),
                                          ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                },
              ),
              if (replyUsername != null)
                _ReplyBanner(username: replyUsername, onCancel: () => _cubit.setReplyTarget(null)),
              const Divider(height: 1),
              _CommentInputBar(
                controller: _inputController,
                replyUsername: replyUsername,
                submitting: _submitting,
                onSubmit: _submit,
              ),
            ],
          );
        },
      ),
    );
  }

  String? _usernameForComment(PostCommentsLoaded? loaded, String commentId) {
    if (loaded == null) return null;
    for (final thread in loaded.threads) {
      if (thread.root.comment.id == commentId) return thread.root.authorUsername;
      for (final reply in thread.replies) {
        if (reply.comment.id == commentId) return reply.authorUsername;
      }
    }
    return null;
  }
}

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.username, required this.onCancel});

  final String username;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.colors.surfaceSoft,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Ответ для $username',
              style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(AppIcons.closeRounded.icon, size: 18, color: context.colors.subTextColor),
          ),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.replyUsername,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? replyUsername;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: AppField(
          controller: controller,
          hintText: replyUsername == null ? 'Добавьте комментарий…' : 'Ответить $replyUsername…',
          textInputAction: TextInputAction.send,
          isEnabled: !submitting,
          suffixIcon: IconButton(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(AppIcons.send.icon, color: context.colors.primary),
          ),
        ),
      ),
    );
  }
}
