import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:flutter/material.dart';

enum ChatMessageAction { forward, edit, delete }

abstract final class ChatMessageActionsSheet {
  static Future<ChatMessageAction?> show(
    BuildContext context, {
    required ChatMessage message,
  }) {
    return AppBottomSheet.show<ChatMessageAction>(
      context: context,
      title: 'Ещё',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionTile(
            icon: AppIcons.arrowForward.icon,
            label: 'Переслать',
            onTap: () => Navigator.of(context).pop(ChatMessageAction.forward),
          ),
          if (message.isMine && message.kind == 'text' && !message.isPending) ...[
            _ActionTile(
              icon: AppIcons.editOutlined.icon,
              label: 'Изменить',
              onTap: () => Navigator.of(context).pop(ChatMessageAction.edit),
            ),
            _ActionTile(
              icon: AppIcons.delete.icon,
              label: 'Удалить',
              destructive: true,
              onTap: () => Navigator.of(context).pop(ChatMessageAction.delete),
            ),
          ],
        ],
      ),
    );
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
      color: Colors.transparent,
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
