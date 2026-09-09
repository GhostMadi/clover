import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reply_preview.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_geometry.dart';
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ChatGeometry.replyRadius),
        border: Border(
          left: BorderSide(color: accentColor, width: ChatGeometry.replyAccentWidth),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ответ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.base(
              12,
              color: accentColor,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            preview.previewText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.base(13, color: textColor.withValues(alpha: 0.9), height: 1.2),
          ),
        ],
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
      margin: EdgeInsets.fromLTRB(ChatGeometry.listHorizontalPadding, 0, ChatGeometry.listHorizontalPadding, 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(ChatGeometry.replyRadius),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            width: ChatGeometry.replyAccentWidth,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                  style: AppTextStyle.base(13, color: context.colors.textColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: Icon(AppIcons.close.icon, color: context.colors.iconMuted, size: 20),
          ),
        ],
      ),
    );
  }
}
