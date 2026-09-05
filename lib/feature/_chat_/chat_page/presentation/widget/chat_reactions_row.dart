import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_reaction.dart';
import 'package:flutter/material.dart';

class ChatReactionsRow extends StatelessWidget {
  const ChatReactionsRow({
    super.key,
    required this.reactions,
    required this.isMine,
    this.onReactionTap,
  });

  final List<ChatMessageReaction> reactions;
  final bool isMine;
  final ValueChanged<String>? onReactionTap;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final reaction in reactions)
            if (reaction.emoji.isNotEmpty && reaction.count > 0)
              _ReactionChip(
                reaction: reaction,
                onTap: onReactionTap == null ? null : () => onReactionTap!(reaction.emoji),
              ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.reaction, this.onTap});

  final ChatMessageReaction reaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${reaction.count}',
                style: AppTextStyle.base(
                  12,
                  color: colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
