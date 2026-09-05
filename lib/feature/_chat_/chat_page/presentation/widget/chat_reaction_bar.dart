import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Instagram-style панель реакций у нижнего края.
class ChatReactionBar extends StatelessWidget {
  const ChatReactionBar({
    super.key,
    required this.message,
    required this.onEmojiSelected,
    this.onMore,
  });

  final ChatMessage message;
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback? onMore;

  static const quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
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
          children: [
            for (final emoji in quickEmojis)
              _EmojiChip(
                emoji: emoji,
                selected: message.myReactions.contains(emoji),
                onTap: () => onEmojiSelected(emoji),
              ),
            if (onMore != null) ...[
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: colors.border.withValues(alpha: 0.7),
              ),
              _MoreChip(onTap: onMore!),
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
        color: selected ? context.colors.primary.withValues(alpha: 0.12) : Colors.transparent,
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

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.onTap});

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
          child: Icon(AppIcons.more.icon, color: context.colors.iconMuted, size: 22),
        ),
      ),
    );
  }
}

/// Long-press → реакции снизу; tap вне — закрыть.
class ChatReactionOverlay extends StatelessWidget {
  const ChatReactionOverlay({
    super.key,
    required this.message,
    required this.onDismiss,
    required this.onEmojiSelected,
    this.onMore,
    this.bottomInset = 96,
  });

  final ChatMessage message;
  final VoidCallback onDismiss;
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback? onMore;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: Container(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset + MediaQuery.paddingOf(context).bottom,
          child: ChatReactionBar(
            message: message,
            onEmojiSelected: (emoji) {
              HapticFeedback.selectionClick();
              onEmojiSelected(emoji);
            },
            onMore: onMore,
          ),
        ),
      ],
    );
  }
}

abstract final class ChatReactionPicker {
  static const quickEmojis = ChatReactionBar.quickEmojis;

  @Deprecated('Use ChatReactionOverlay on long press')
  static Future<String?> show(BuildContext context) async {
    return null;
  }
}
