import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_message_context_menu.dart';
import 'package:flutter/material.dart';

/// Fallback bottom sheet «Ещё» (основной UX — [ChatMessageContextMenu]).
abstract final class ChatMessageActionsSheet {
  static Future<ChatMessageAction?> show(
    BuildContext context, {
    required ChatMessage message,
  }) {
    final actions = ChatMessageContextMenu.actionsFor(message)
        .where((a) => a != ChatMessageAction.reply && a != ChatMessageAction.copy && a != ChatMessageAction.star)
        .toList(growable: false);

    return AppBottomSheet.show<ChatMessageAction>(
      context: context,
      title: 'Ещё',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actions)
            _ActionTile(
              icon: _icon(action),
              label: _label(action),
              destructive: action == ChatMessageAction.delete,
              onTap: () => Navigator.of(context).pop(action),
            ),
        ],
      ),
    );
  }

  static String _label(ChatMessageAction action) {
    return switch (action) {
      ChatMessageAction.reply => 'Ответить',
      ChatMessageAction.forward => 'Переслать',
      ChatMessageAction.copy => 'Копировать',
      ChatMessageAction.star => 'В Избранные',
      ChatMessageAction.edit => 'Изменить',
      ChatMessageAction.delete => 'Удалить',
    };
  }

  static IconData _icon(ChatMessageAction action) {
    return switch (action) {
      ChatMessageAction.reply => AppIcons.replyOutlined.icon,
      ChatMessageAction.forward => AppIcons.arrowForward.icon,
      ChatMessageAction.copy => AppIcons.copy.icon,
      ChatMessageAction.star => AppIcons.bookmark.icon,
      ChatMessageAction.edit => AppIcons.editOutlined.icon,
      ChatMessageAction.delete => AppIcons.delete.icon,
    };
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? context.colors.destructive : context.colors.textColor;
    return Material(
      color: const Color(0x00000000),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(label, style: AppTextStyle.base(16, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
