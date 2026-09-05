import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/image_select/app_image_selector_page.dart';
import 'package:clover/feature/_chat_/chat/data/chat_image_compress.dart';
import 'package:clover/feature/_chat_/chat/data/models/chat_attachment_upload.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_search_hit.dart';
import 'package:clover/feature/_chat_/chat/presentation/widget/chat_forward_sheet.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/cubit/chat_thread_cubit.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/utils/chat_message_date_grouping.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_composer.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_composer_attachments_preview.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_date_section_header.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_message_actions_sheet.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_message_bubble.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_message_interaction.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_reaction_bar.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_reply_quote.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_send_flight.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

@RoutePage()
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.chatId,
    this.otherUserId,
    required this.username,
    this.isGroup = false,
  });

  final String? chatId;
  final String? otherUserId;
  final String username;
  final bool isGroup;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatThreadCubit _cubit;
  late final TextEditingController _composerController;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  bool _searchMode = false;
  bool _searchLoading = false;
  List<ChatSearchHit> _searchHits = const [];
  ChatMessage? _reactionTarget;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ChatThreadCubit>();
    final peerId = widget.otherUserId?.trim();
    if (peerId != null && peerId.isNotEmpty) {
      _cubit.openWithOtherUser(peerId);
    } else {
      _cubit.load(widget.chatId!.trim());
    }
    _composerController = TextEditingController();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 120) {
      _cubit.loadOlderMessages();
    }
  }

  void _retryLoad() {
    final peerId = widget.otherUserId?.trim();
    if (peerId != null && peerId.isNotEmpty) {
      _cubit.openWithOtherUser(peerId);
      return;
    }
    final chatId = widget.chatId?.trim();
    if (chatId != null && chatId.isNotEmpty) {
      _cubit.load(chatId);
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  String get _title {
    final raw = widget.username.trim();
    if (raw.isEmpty) return widget.isGroup ? 'Группа' : '@user';
    if (widget.isGroup) return raw;
    return raw.startsWith('@') ? raw : '@$raw';
  }

  void _sendMessage() {
    final text = _composerController.text.trim();
    final state = _cubit.state;
    if (state is! ChatThreadLoaded) return;

    if (state.editingMessage != null) {
      if (text.isEmpty) return;
      _cubit.sendMessage(text);
      _composerController.clear();
      _cubit.clearComposerContext();
      _scrollToLatestMessages(animated: !_isNearLatestMessages());
      return;
    }

    final attachments = state.pendingAttachments;
    if (text.isEmpty && attachments.isEmpty) return;

    final shouldScrollToLatest = !_isNearLatestMessages();

    if (attachments.isNotEmpty) {
      _cubit.sendAttachments(
        attachments,
        caption: text.isEmpty ? null : text,
      );
    } else {
      _cubit.sendMessage(text);
    }

    _composerController.clear();
    _cubit.clearComposerContext();
    _scrollToLatestMessages(animated: shouldScrollToLatest);
  }

  bool _isNearLatestMessages() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= 96;
  }

  void _scrollToLatestMessages({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  void _scrollToBottom({bool animated = false}) {
    _scrollToLatestMessages(animated: animated);
  }

  void _scrollToMessage(String messageId) {
    final state = _cubit.state;
    if (state is! ChatThreadLoaded) return;

    final sections = ChatMessageDateGrouping.group(state.messages);
    final itemCount = ChatMessageDateGrouping.listItemCount(sections);
    var targetIndex = -1;

    for (var index = 0; index < itemCount; index++) {
      if (ChatMessageDateGrouping.isHeaderIndex(sections, index)) continue;
      final message = ChatMessageDateGrouping.messageAt(sections, index);
      if (message?.id == messageId) {
        targetIndex = index;
        break;
      }
    }

    if (targetIndex < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const estimatedItemHeight = 72.0;
      final offset = (targetIndex * estimatedItemHeight).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() {
        _searchHits = const [];
        _searchLoading = false;
      });
      return;
    }

    setState(() => _searchLoading = true);
    final hits = await _cubit.searchMessages(q);
    if (!mounted) return;
    setState(() {
      _searchHits = hits;
      _searchLoading = false;
    });
  }

  void _toggleSearchMode() {
    setState(() {
      _searchMode = !_searchMode;
      if (!_searchMode) {
        _searchController.clear();
        _searchHits = const [];
        _searchLoading = false;
      }
    });
  }

  void _dismissReactionBar() {
    if (_reactionTarget == null) return;
    setState(() => _reactionTarget = null);
  }

  void _showReactionBar(ChatMessage message) {
    setState(() => _reactionTarget = message);
  }

  Future<void> _onReactionEmoji(String emoji) async {
    final target = _reactionTarget;
    if (target == null || emoji.trim().isEmpty) return;
    _dismissReactionBar();
    await _cubit.toggleReaction(target.id, emoji.trim());
  }

  void _onSwipeReply(ChatMessage message) {
    _dismissReactionBar();
    _cubit.setReplyTo(message);
  }

  Future<void> _handleMessageMore(ChatMessage message) async {
    if (message.isPending) return;

    final action = await ChatMessageActionsSheet.show(context, message: message);
    if (!mounted || action == null) return;

    switch (action) {
      case ChatMessageAction.forward:
        await ChatForwardSheet.show(context, message: message);
      case ChatMessageAction.edit:
        _cubit.setEditingMessage(message);
        _composerController.text = message.text;
        _composerController.selection = TextSelection.collapsed(offset: message.text.length);
      case ChatMessageAction.delete:
        await _cubit.deleteMessage(message.id);
    }
  }

  void _onAttachmentSelected(ChatAttachmentAction action) {
    switch (action) {
      case ChatAttachmentAction.photo:
        _pickPhoto();
      case ChatAttachmentAction.document:
        _pickDocument();
    }
  }

  Future<void> _pickPhoto() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => AppImageSelectorPage(
          title: 'Фото',
          confirmLabel: 'Готово',
          maxSelectionCount: 10,
          onConfirmed: (result) async {
            Navigator.of(context).pop();
            await _stageSelectedPhotos(result.assets);
          },
        ),
      ),
    );
  }

  Future<void> _stageSelectedPhotos(List<AssetEntity> assets) async {
    if (assets.isEmpty) return;

    final uploads = <ChatAttachmentUpload>[];
    for (final asset in assets) {
      final file = await asset.file;
      if (file == null) continue;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;

      final title = await asset.titleAsync;
      final filename = title.trim().isNotEmpty ? title.trim() : 'photo.jpg';
      uploads.add(
        await ChatImageCompress.prepareUpload(
          bytes: bytes,
          filename: filename,
        ),
      );
    }

    if (uploads.isEmpty) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось прочитать фото', kind: AppSnackBarKind.error);
      return;
    }

    _cubit.addPendingAttachments(uploads);
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final uploads = <ChatAttachmentUpload>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      final filename = file.name.trim().isNotEmpty ? file.name.trim() : 'document.bin';
      uploads.add(
        ChatAttachmentUpload(
          bytes: bytes,
          filename: filename,
          mime: _mimeFromFilename(filename, fallback: file.extension),
        ),
      );
    }

    if (uploads.isEmpty) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Не удалось прочитать документ', kind: AppSnackBarKind.error);
      return;
    }

    _cubit.addPendingAttachments(uploads);
  }

  String _mimeFromFilename(String filename, {String? fallback}) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    final ext = fallback?.trim().toLowerCase();
    if (ext == 'pdf') return 'application/pdf';
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ChatThreadCubit, ChatThreadState>(
        listenWhen: (prev, next) {
          if (next is ChatThreadLoaded && next.sendError != null) return true;
          if (next is ChatThreadLoaded && next.editingMessage != null) {
            if (prev is! ChatThreadLoaded) return true;
            return prev.editingMessage?.id != next.editingMessage?.id;
          }
          if (next is! ChatThreadLoaded || next.messages.isEmpty) return false;
          if (prev is! ChatThreadLoaded) return true;
          return next.messages.length != prev.messages.length && !next.isLoadingOlder;
        },
        listener: (context, state) {
          if (state is ChatThreadLoaded && state.sendError != null) {
            AppSnackBar.show(context, message: state.sendError!, kind: AppSnackBarKind.error);
            return;
          }
          if (state is ChatThreadLoaded && state.editingMessage != null) {
            final text = state.editingMessage!.text;
            if (_composerController.text != text) {
              _composerController.text = text;
              _composerController.selection = TextSelection.collapsed(offset: text.length);
            }
            return;
          }
          if (state is ChatThreadLoaded && state.messages.isNotEmpty) {
            _scrollToBottom(animated: state.isFromCache == false);
          }
        },
        child: Scaffold(
          backgroundColor: context.colors.pageBackground,
          appBar: AppBar(
            backgroundColor: context.colors.pageBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(AppIcons.arrowBackRounded.icon),
              color: context.colors.textColor,
              onPressed: () => context.router.maybePop(),
            ),
            title: Row(
              children: [
                if (widget.isGroup) ...[
                  Icon(AppIcons.groupOutlined.icon, size: 18, color: context.colors.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: BlocBuilder<ChatThreadCubit, ChatThreadState>(
                    buildWhen: (prev, next) {
                      if (prev is ChatThreadLoaded && next is ChatThreadLoaded) {
                        return prev.peerIsTyping != next.peerIsTyping;
                      }
                      return next is ChatThreadLoaded;
                    },
                    builder: (context, state) {
                      final isTyping = state is ChatThreadLoaded && state.peerIsTyping;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.base(17, color: context.colors.textColor, fontWeight: FontWeight.w700),
                          ),
                          if (isTyping)
                            Text(
                              'печатает…',
                              style: AppTextStyle.base(12, color: context.colors.subTextColor),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_searchMode ? AppIcons.close.icon : AppIcons.searchRounded.icon),
                color: context.colors.textColor,
                onPressed: _toggleSearchMode,
              ),
            ],
          ),
          body: BlocBuilder<ChatThreadCubit, ChatThreadState>(
            builder: (context, state) {
              return Column(
                children: [
                  if (_searchMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: AppField(
                        controller: _searchController,
                        hintText: 'Поиск по сообщениям',
                        prefixIcon: AppIcons.searchRounded.icon,
                        textInputAction: TextInputAction.search,
                        onChanged: _runSearch,
                      ),
                    ),
                  if (_searchMode && _searchLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
                      ),
                    ),
                  if (_searchMode && _searchHits.isNotEmpty)
                    SizedBox(
                      height: 132,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchHits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final hit = _searchHits[index];
                          return Material(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                _scrollToMessage(hit.messageId);
                                _toggleSearchMode();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  hit.preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.base(14, color: context.colors.textColor),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: switch (state) {
                      ChatThreadInitial() || ChatThreadLoading() => Center(
                        child: CircularProgressIndicator(color: context.colors.primary),
                      ),
                      ChatThreadError(:final message) => _ChatThreadErrorView(
                        message: message,
                        onRetry: _retryLoad,
                      ),
                      ChatThreadLoaded(
                        :final messages,
                        :final isSending,
                        :final isRefreshing,
                        :final isOpeningConversation,
                        :final replyToMessage,
                        :final editingMessage,
                        :final isLoadingOlder,
                        :final pendingAttachments,
                      ) =>
                        Stack(
                        children: [
                          if (isLoadingOlder)
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
                                ),
                              ),
                            ),
                          if (isRefreshing || isOpeningConversation)
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
                                ),
                              ),
                            ),
                          if (messages.isEmpty)
                            Center(
                              child: Text(
                                isOpeningConversation ? 'Открываем чат…' : 'Напишите первое сообщение',
                                style: AppTextStyle.base(15, color: context.colors.subTextColor),
                              ),
                            )
                          else
                            Builder(
                              builder: (context) {
                                final sections = ChatMessageDateGrouping.group(messages);
                                final itemCount = ChatMessageDateGrouping.listItemCount(sections);

                                return ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 100),
                                  itemCount: itemCount,
                                  itemBuilder: (context, index) {
                                    if (ChatMessageDateGrouping.isHeaderIndex(sections, index)) {
                                      final title = ChatMessageDateGrouping.headerTitleAt(sections, index);
                                      if (title == null) return const SizedBox.shrink();
                                      return ChatDateSectionHeader(title: title);
                                    }

                                    final message = ChatMessageDateGrouping.messageAt(sections, index);
                                    if (message == null) return const SizedBox.shrink();
                                    final messageKey = message.clientMessageId ?? message.id;
                                    return ChatMessageEntrance(
                                      key: ValueKey('entrance_$messageKey'),
                                      animate: message.isMine && message.isPending,
                                      child: ChatMessageInteraction(
                                        message: message,
                                        onLongPressReaction:
                                            message.isPending ? null : () => _showReactionBar(message),
                                        onSwipeReply: message.isPending ? null : () => _onSwipeReply(message),
                                        child: ChatMessageBubble(
                                          message: message,
                                          onReactionToggle: (emoji) => _cubit.toggleReaction(message.id, emoji),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (replyToMessage != null)
                                  ChatComposerContextBar.reply(
                                    message: replyToMessage,
                                    onClose: _cubit.clearComposerContext,
                                  ),
                                if (editingMessage != null)
                                  ChatComposerContextBar.edit(
                                    message: editingMessage,
                                    onClose: () {
                                      _cubit.clearComposerContext();
                                      _composerController.clear();
                                    },
                                  ),
                                if (pendingAttachments.isNotEmpty)
                                  ChatComposerAttachmentsPreview(
                                    attachments: pendingAttachments,
                                    onRemove: _cubit.removePendingAttachmentAt,
                                  ),
                                ChatComposer(
                                  controller: _composerController,
                                  onSend: _sendMessage,
                                  onAttachmentSelected: _onAttachmentSelected,
                                  isSending: isSending || isOpeningConversation,
                                  hasAttachments: pendingAttachments.isNotEmpty,
                                  onChanged: (_) => _cubit.notifyTyping(),
                                ),
                              ],
                            ),
                          ),
                          if (_reactionTarget != null)
                            ChatReactionOverlay(
                              message: _reactionTarget!,
                              onDismiss: _dismissReactionBar,
                              onEmojiSelected: _onReactionEmoji,
                              onMore: () => _handleMessageMore(_reactionTarget!),
                              bottomInset: 118 +
                                  ((replyToMessage != null || editingMessage != null) ? 58 : 0) +
                                  (pendingAttachments.isNotEmpty ? 96 : 0),
                            ),
                        ],
                      ),
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChatThreadErrorView extends StatelessWidget {
  const _ChatThreadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.errorOutline.icon, size: 48, color: context.colors.iconMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: context.colors.primary),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
