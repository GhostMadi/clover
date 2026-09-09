import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_peer_accent.dart';
import 'package:clover/feature/_chat_/message_page/data/models/message_chat_preview.dart';
import 'package:clover/feature/_chat_/message_page/presentation/form/message_chat_time_formatting.dart';
import 'package:flutter/material.dart';

class MessageChatTile extends StatelessWidget {
  const MessageChatTile({super.key, required this.chat, this.onTap});

  final MessageChatPreview chat;
  final VoidCallback? onTap;

  static const double _avatarSize = 52;

  @override
  Widget build(BuildContext context) {
    final username = chat.username.trim();
    final handle = username.startsWith('@') ? username : username;
    final lastMessage = chat.lastMessage.trim();
    final timeLabel = MessageChatTimeFormatting.format(chat.lastMessageAt);
    final hasUnread = chat.hasUnread;
    final accent = ChatPeerAccent.forSeed(context.colors, chat.id.isNotEmpty ? chat.id : username);

    return Material(
      color: hasUnread ? accent.fill.withValues(alpha: 0.45) : context.colors.pageBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageChatAvatar(
                username: username,
                avatarUrl: chat.avatarUrl,
                isGroup: chat.isGroup,
                accent: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            handle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.base(
                              16,
                              color: context.colors.textColor,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: AppTextStyle.base(
                            12,
                            color: hasUnread ? accent.ink : context.colors.subTextColor,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.base(
                              14,
                              color: hasUnread ? context.colors.textColor : context.colors.subTextColor,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MessageReadStatus(chat: chat, accent: accent),
                      ],
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

class _MessageChatAvatar extends StatelessWidget {
  const _MessageChatAvatar({
    required this.username,
    required this.accent,
    this.avatarUrl,
    this.isGroup = false,
  });

  final String username;
  final String? avatarUrl;
  final bool isGroup;
  final ChatPeerAccent accent;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final initial = username.isNotEmpty ? username.characters.first.toUpperCase() : '?';

    if (isGroup && (url == null || url.isEmpty)) {
      return CircleAvatar(
        radius: MessageChatTile._avatarSize / 2,
        backgroundColor: accent.fill,
        child: Icon(AppIcons.groupOutlined.icon, color: accent.ink, size: 24),
      );
    }

    return CircleAvatar(
      radius: MessageChatTile._avatarSize / 2,
      backgroundColor: accent.fill,
      backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: url == null || url.isEmpty
          ? Text(
              initial,
              style: AppTextStyle.base(18, color: accent.ink, fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}

class _MessageReadStatus extends StatelessWidget {
  const _MessageReadStatus({required this.chat, required this.accent});

  final MessageChatPreview chat;
  final ChatPeerAccent accent;

  @override
  Widget build(BuildContext context) {
    if (!chat.isLastMessageMine) {
      if (chat.hasUnread) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: accent.ink, shape: BoxShape.circle),
        );
      }
      return const SizedBox(width: 10, height: 10);
    }

    final icon = chat.isRead ? AppIcons.doneAll.icon : AppIcons.done.icon;
    final color = chat.isRead ? context.colors.primary : context.colors.iconMuted;

    return Icon(icon, size: 18, color: color);
  }
}
