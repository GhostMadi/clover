import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/feature/_chat_/message_page/data/models/message_chat_preview.dart';
import 'package:clover/feature/_chat_/message_page/presentation/cubit/message_list_cubit.dart';
import 'package:clover/feature/_chat_/message_page/presentation/widget/message_chat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  late final MessageListCubit _cubit;
  late final TextEditingController _searchController;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _cubit = sl<MessageListCubit>()..load();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Сообщения',
                  style: AppTextStyle.base(24, color: AppColors.textColor, fontWeight: FontWeight.w800),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppField(
                  controller: _searchController,
                  hintText: 'Поиск по чатам',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: BlocBuilder<MessageListCubit, MessageListState>(
                  builder: (context, state) {
                    return switch (state) {
                      MessageListInitial() || MessageListLoading() => Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      MessageListError(:final message) => _MessageErrorState(
                        message: message,
                        onRetry: _cubit.load,
                      ),
                      MessageListLoaded(:final chats, :final isRefreshing) => _buildChatList(
                        chats: _filterChats(chats),
                        hasAnyChats: chats.isNotEmpty,
                        isRefreshing: isRefreshing,
                      ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList({
    required List<MessageChatPreview> chats,
    required bool hasAnyChats,
    required bool isRefreshing,
  }) {
    if (!hasAnyChats) {
      return AppRefresh(
        onRefresh: _cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: AppNavBar.scrollBottomClearance(context)),
          children: const [
            SizedBox(height: 120),
            _MessageEmptyState(
              title: 'Пока нет чатов',
              subtitle: 'Начните переписку с другого профиля',
            ),
          ],
        ),
      );
    }

    if (chats.isEmpty) {
      return AppRefresh(
        onRefresh: _cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: AppNavBar.scrollBottomClearance(context)),
          children: const [
            SizedBox(height: 120),
            _MessageEmptyState(
              title: 'Чаты не найдены',
              subtitle: 'Попробуйте другой запрос',
            ),
          ],
        ),
      );
    }

    return AppRefresh(
      onRefresh: _cubit.refresh,
      child: Stack(
        children: [
          ListView.separated(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: AppNavBar.scrollBottomClearance(context)),
            itemCount: chats.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.65),
              indent: 80,
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return MessageChatTile(
                chat: chat,
                onTap: () => context.router.push(
                  ChatRoute(chatId: chat.id, username: chat.username),
                ),
              );
            },
          ),
          if (isRefreshing)
            Positioned(
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
        ],
      ),
    );
  }
}

class _MessageErrorState extends StatelessWidget {
  const _MessageErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.iconMuted),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(16, color: AppColors.textColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
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

class _MessageEmptyState extends StatelessWidget {
  const _MessageEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.iconMuted),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(16, color: AppColors.textColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: AppColors.subTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
