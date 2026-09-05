import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reply_preview.dart';
import 'package:flutter/material.dart';

class ChatReplyQuote extends StatelessWidget {
  const ChatReplyQuote({
    super.key,
    required this.preview,
    required this.textColor,
    required this.accentColor,
  });

  final ChatMessageReplyPreview preview;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Text(
        preview.previewText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.base(13, color: textColor.withValues(alpha: 0.92), height: 1.25),
      ),
    );
  }
}

class ChatComposerContextBar extends StatelessWidget {
  const ChatComposerContextBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  factory ChatComposerContextBar.reply({
    required ChatMessage message,
    required VoidCallback onClose,
  }) {
    return ChatComposerContextBar(
      title: 'Ответ',
      subtitle: message.text.trim().isNotEmpty
          ? message.text.trim()
          : (message.replyPreview?.previewText ?? 'Сообщение'),
      onClose: onClose,
    );
  }

  factory ChatComposerContextBar.edit({
    required ChatMessage message,
    required VoidCallback onClose,
  }) {
    return ChatComposerContextBar(
      title: 'Редактирование',
      subtitle: message.text,
      onClose: onClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.base(12, color: context.colors.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(14, color: context.colors.textColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(AppIcons.close.icon, color: context.colors.iconMuted, size: 20),
          ),
        ],
      ),
    );
  }
}
