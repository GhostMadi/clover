import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
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

    return Material(
      color: hasUnread ? AppColors.surfaceSoftGreen.withValues(alpha: 0.35) : AppColors.pageBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageChatAvatar(username: username, avatarUrl: chat.avatarUrl),
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
                              color: AppColors.textColor,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: AppTextStyle.base(
                            12,
                            color: hasUnread ? AppColors.primary : AppColors.subTextColor,
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
                              color: hasUnread ? AppColors.textColor : AppColors.subTextColor,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MessageReadStatus(chat: chat),
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
  const _MessageChatAvatar({required this.username, this.avatarUrl});

  final String username;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final initial = username.isNotEmpty ? username.characters.first.toUpperCase() : '?';

    return CircleAvatar(
      radius: MessageChatTile._avatarSize / 2,
      backgroundColor: AppColors.surfaceSoft,
      backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: url == null || url.isEmpty
          ? Text(
              initial,
              style: AppTextStyle.base(18, color: AppColors.primary, fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}

class _MessageReadStatus extends StatelessWidget {
  const _MessageReadStatus({required this.chat});

  final MessageChatPreview chat;

  @override
  Widget build(BuildContext context) {
    if (!chat.isLastMessageMine) {
      if (chat.hasUnread) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        );
      }
      return const SizedBox(width: 10, height: 10);
    }

    final icon = chat.isRead ? Icons.done_all_rounded : Icons.done_rounded;
    final color = chat.isRead ? AppColors.primary : AppColors.iconMuted;

    return Icon(icon, size: 18, color: color);
  }
}
