import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:flutter/material.dart';

/// Панель быстрых реакций (emoji + «+»).
class ChatReactionBar extends StatelessWidget {
  const ChatReactionBar({
    super.key,
    required this.message,
    required this.onEmojiSelected,
    this.onAddEmoji,
    @Deprecated('Use onAddEmoji') this.onMore,
  });

  final ChatMessage message;
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback? onAddEmoji;
  @Deprecated('Use onAddEmoji')
  final VoidCallback? onMore;

  static const quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final addTap = onAddEmoji ?? onMore;

    return Material(
      color: const Color(0x00000000),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colors.border.withValues(alpha: 0.65)),
          boxShadow: [
            BoxShadow(
              color: colors.shadowDark.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in quickEmojis)
              _EmojiChip(
                emoji: emoji,
                selected: message.myReactions.contains(emoji),
                onTap: () => onEmojiSelected(emoji),
              ),
            if (addTap != null) ...[
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: colors.border.withValues(alpha: 0.7),
              ),
              _AddChip(onTap: addTap),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({
    required this.emoji,
    required this.onTap,
    this.selected = false,
  });

  final String emoji;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? context.colors.primary.withValues(alpha: 0.12) : const Color(0x00000000),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(AppIcons.add.icon, color: context.colors.iconMuted, size: 22),
        ),
      ),
    );
  }
}

abstract final class ChatReactionPicker {
  static const quickEmojis = ChatReactionBar.quickEmojis;
}
