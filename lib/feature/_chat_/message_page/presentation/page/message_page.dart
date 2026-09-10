import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_state.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
// import 'package:clover/feature/_chat_/chat/presentation/widget/chat_group_create_sheet.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_search_hit.dart';
import 'package:clover/feature/_chat_/message_page/data/models/message_chat_preview.dart';
import 'package:clover/feature/_chat_/message_page/presentation/cubit/message_list_cubit.dart';
import 'package:clover/feature/_chat_/message_page/presentation/form/message_chat_time_formatting.dart';
import 'package:clover/feature/_chat_/message_page/presentation/widget/message_chat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> with WidgetsBindingObserver {
  late final MessageListCubit _cubit;
  late final ChatRepository _chatRepository;
  late final TextEditingController _searchController;

  String _query = '';
  bool _messageSearchLoading = false;
  List<ChatSearchHit> _messageHits = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = sl<MessageListCubit>()..load();
    _chatRepository = sl<ChatRepository>();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_cubit.softRefresh());
    }
  }

  Future<void> _openChat({
    required String chatId,
    required String username,
    bool isGroup = false,
  }) async {
    await context.router.push(
      ChatRoute(
        chatId: chatId,
        username: username,
        isGroup: isGroup,
      ),
    );
    if (!mounted) return;
    unawaited(_cubit.softRefresh());
  }

  List<MessageChatPreview> _filterChats(List<MessageChatPreview> chats) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return chats;

    return chats
        .where(
          (chat) => chat.username.toLowerCase().contains(q) || chat.lastMessage.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  Future<void> _searchMessages(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() {
        _messageHits = const [];
        _messageSearchLoading = false;
      });
      return;
    }

    setState(() => _messageSearchLoading = true);
    try {
      final hits = await _chatRepository.searchMessages(query: q);
      if (!mounted) return;
      setState(() {
        _messageHits = hits;
        _messageSearchLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messageHits = const [];
        _messageSearchLoading = false;
      });
    }
  }

  // Future<void> _createGroup() async {
  //   final result = await ChatGroupCreateSheet.show(context);
  //   if (!mounted || result == null) return;
  //
  //   await context.router.push(
  //     ChatRoute(
  //       chatId: result.conversationId,
  //       username: result.title,
  //       isGroup: true,
  //     ),
  //   );
  //   if (!mounted) return;
  //   _cubit.refresh();
  // }

  MessageChatPreview? _chatById(List<MessageChatPreview> chats, String conversationId) {
    for (final chat in chats) {
      if (chat.id == conversationId) return chat;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: context.colors.pageBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Сообщения',
                  style: AppTextStyle.base(24, color: context.colors.textColor, fontWeight: FontWeight.w800),
                ),
              ),
              // TODO: групповые чаты — вернуть кнопку, когда будет готов UX админки.
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: Text(
              //           'Сообщения',
              //           style: AppTextStyle.base(24, color: context.colors.textColor, fontWeight: FontWeight.w800),
              //         ),
              //       ),
              //       IconButton(
              //         onPressed: _createGroup,
              //         icon: Icon(AppIcons.groupOutlined.icon, color: context.colors.primary),
              //         tooltip: 'Новая группа',
              //       ),
              //     ],
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppField(
                  controller: _searchController,
                  hintText: 'Поиск по чатам и сообщениям',
                  prefixIcon: AppIcons.searchRounded.icon,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    setState(() => _query = value);
                    _searchMessages(value);
                  },
                ),
              ),
              Expanded(
                child: BlocBuilder<MessageListCubit, MessageListState>(
                  builder: (context, state) {
                    final isLoading = state is MessageListLoading;
                    final errorMessage = switch (state) {
                      MessageListError(:final message) => message,
                      _ => null,
                    };
                    final loaded = state is MessageListLoaded ? state : null;
                    final filteredChats = loaded == null ? const <MessageChatPreview>[] : _filterChats(loaded.chats);
                    final screenState = AppState.resolve(
                      isLoading: isLoading,
                      errorMessage: errorMessage,
                    );

                    return AppState(
                      state: screenState,
                      errorMessage: errorMessage,
                      onRetry: _cubit.load,
                      child: loaded == null
                          ? const SizedBox.shrink()
                          : _buildContent(
                              chats: filteredChats,
                              allChats: loaded.chats,
                              hasAnyChats: loaded.chats.isNotEmpty,
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required List<MessageChatPreview> chats,
    required List<MessageChatPreview> allChats,
    required bool hasAnyChats,
  }) {
    final showMessageHits = _query.trim().length >= 2;

    if (!hasAnyChats && !showMessageHits) {
      return AppRefresh(
        onRefresh: _cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: AppNavBar.scrollBottomClearance(context)),
          children: [
            const SizedBox(height: 120),
            AppState(
              state: AppScreenState.empty,
              emptyIcon: AppIcons.chat.icon,
              emptyTitle: 'Пока нет чатов',
              emptySubtitle: 'Начните переписку с другого профиля',
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    if (chats.isEmpty && _messageHits.isEmpty && !_messageSearchLoading && showMessageHits) {
      return AppRefresh(
        onRefresh: _cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: AppNavBar.scrollBottomClearance(context)),
          children: [
            const SizedBox(height: 120),
            AppState(
              state: AppScreenState.empty,
              emptyIcon: AppIcons.searchRounded.icon,
              emptyTitle: 'Ничего не найдено',
              emptySubtitle: 'Попробуйте другой запрос',
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return AppRefresh(
      onRefresh: _cubit.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: AppNavBar.scrollBottomClearance(context)),
        children: [
          if (showMessageHits) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'В сообщениях',
                style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
              ),
            ),
            if (_messageSearchLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
                  ),
                ),
              )
            else if (_messageHits.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Совпадений в тексте сообщений нет',
                  style: AppTextStyle.base(13, color: context.colors.subTextColor),
                ),
              )
            else
              ...[
                for (final hit in _messageHits.take(20))
                  _MessageSearchTile(
                    hit: hit,
                    chat: _chatById(allChats, hit.conversationId),
                    onTap: () {
                      final chat = _chatById(allChats, hit.conversationId);
                      unawaited(
                        _openChat(
                          chatId: hit.conversationId,
                          username: chat?.username ?? hit.senderUsername ?? 'Чат',
                          isGroup: chat?.isGroup ?? false,
                        ),
                      );
                    },
                  ),
              ],
            if (chats.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Чаты',
                  style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
          for (var index = 0; index < chats.length; index++) ...[
            MessageChatTile(
              chat: chats[index],
              onTap: () => unawaited(
                _openChat(
                  chatId: chats[index].id,
                  username: chats[index].username,
                  isGroup: chats[index].isGroup,
                ),
              ),
            ),
            if (index < chats.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: context.colors.border.withValues(alpha: 0.65),
                indent: 80,
              ),
          ],
        ],
      ),
    );
  }
}

class _MessageSearchTile extends StatelessWidget {
  const _MessageSearchTile({
    required this.hit,
    required this.onTap,
    this.chat,
  });

  final ChatSearchHit hit;
  final MessageChatPreview? chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = chat?.username ?? hit.senderUsername ?? 'Чат';
    final timeLabel = MessageChatTimeFormatting.format(hit.sentAt);

    return Material(
      color: context.colors.pageBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.searchRounded.icon, size: 18, color: context.colors.iconMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.base(14, color: context.colors.textColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: AppTextStyle.base(12, color: context.colors.subTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hit.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
