import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/chat_page/presentation/form/chat_time_formatting.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  static const double _maxWidthFactor = 0.76;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final timeLabel = ChatTimeFormatting.format(message.sentAt);

    final background = isMine ? AppColors.primary : AppColors.surface;
    final textColor = isMine ? AppColors.white : AppColors.textColor;
    final metaColor = isMine ? AppColors.white.withValues(alpha: 0.82) : AppColors.subTextColor;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor),
        child: Container(
          margin: EdgeInsets.only(
            left: isMine ? 40 : 0,
            right: isMine ? 0 : 40,
            bottom: 10,
          ),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: _radius.copyWith(
              bottomRight: isMine ? const Radius.circular(8) : _radius.bottomRight,
              bottomLeft: isMine ? _radius.bottomLeft : const Radius.circular(8),
            ),
            border: isMine
                ? null
                : Border.all(color: AppColors.border.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: (isMine ? AppColors.shadowPrimary : AppColors.shadowDark).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: AppTextStyle.base(15, color: textColor, height: 1.35),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: AppTextStyle.base(11, color: metaColor, fontWeight: FontWeight.w500),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isPending
                          ? Icons.schedule_rounded
                          : (message.isRead ? Icons.done_all_rounded : Icons.done_rounded),
                      size: 14,
                      color: metaColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
