import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/image_select/app_image_selector_page.dart';
import 'package:clover/feature/chat_page/presentation/cubit/chat_thread_cubit.dart';
import 'package:clover/feature/chat_page/presentation/widget/chat_composer.dart';
import 'package:clover/feature/chat_page/presentation/widget/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chatId, required this.username});

  final String chatId;
  final String username;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatThreadCubit _cubit;
  late final TextEditingController _composerController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ChatThreadCubit>()..load(widget.chatId);
    _composerController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  String get _handle {
    final raw = widget.username.trim();
    if (raw.isEmpty) return '@user';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  void _sendMessage() {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    _composerController.clear();
    _cubit.sendMessage(text);
    _scrollToBottom(animated: true);
  }

  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
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
          confirmLabel: 'Отправить',
          maxSelectionCount: 10,
          onConfirmed: (result) {
            Navigator.of(context).pop();
            AppSnackBar.show(
              context,
              message: 'Выбрано фото: ${result.assets.length}',
              kind: AppSnackBarKind.info,
            );
          },
        ),
      ),
    );
  }

  void _pickDocument() {
    AppSnackBar.show(context, message: 'Выбор документа скоро будет доступен', kind: AppSnackBarKind.info);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ChatThreadCubit, ChatThreadState>(
        listenWhen: (prev, next) {
          if (next is ChatThreadLoaded && next.sendError != null) return true;
          if (next is! ChatThreadLoaded || next.messages.isEmpty) return false;
          if (prev is! ChatThreadLoaded) return true;
          return next.messages.length != prev.messages.length;
        },
        listener: (context, state) {
          if (state is ChatThreadLoaded && state.sendError != null) {
            AppSnackBar.show(context, message: state.sendError!, kind: AppSnackBarKind.error);
            return;
          }
          if (state is ChatThreadLoaded && state.messages.isNotEmpty) {
            _scrollToBottom(animated: state.isFromCache == false);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            backgroundColor: AppColors.pageBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textColor,
              onPressed: () => context.router.maybePop(),
            ),
            title: Text(
              _handle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.base(17, color: AppColors.textColor, fontWeight: FontWeight.w700),
            ),
          ),
          body: BlocBuilder<ChatThreadCubit, ChatThreadState>(
            builder: (context, state) {
              return switch (state) {
                ChatThreadInitial() || ChatThreadLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                ChatThreadError(:final message) => _ChatThreadErrorView(
                  message: message,
                  onRetry: () => _cubit.load(widget.chatId),
                ),
                ChatThreadLoaded(:final messages, :final isSending, :final isRefreshing) => Stack(
                  children: [
                    if (isRefreshing)
                      const Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                      ),
                    if (messages.isEmpty)
                      Center(
                        child: Text(
                          'Напишите первое сообщение',
                          style: AppTextStyle.base(15, color: AppColors.subTextColor),
                        ),
                      )
                    else
                      ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 88),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return ChatMessageBubble(message: messages[index]);
                        },
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ChatComposer(
                        controller: _composerController,
                        onSend: _sendMessage,
                        onAttachmentSelected: _onAttachmentSelected,
                        isSending: isSending,
                      ),
                    ),
                  ],
                ),
              };
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
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.iconMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(16, color: AppColors.textColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
