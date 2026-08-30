import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/form/chat_time_formatting.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_post_ref_preview.dart';
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = message.isPostShare
        ? (ChatPostRefPreview.width + 28).clamp(0.0, screenWidth * _maxWidthFactor)
        : screenWidth * _maxWidthFactor;

    final background = isMine ? AppColors.primary : AppColors.surface;
    final textColor = isMine ? AppColors.white : AppColors.textColor;
    final metaColor = isMine ? AppColors.white.withValues(alpha: 0.82) : AppColors.subTextColor;

    final borderRadius = _radius.copyWith(
      bottomRight: isMine ? const Radius.circular(8) : _radius.bottomRight,
      bottomLeft: isMine ? _radius.bottomLeft : const Radius.circular(8),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 40 : 0,
        right: isMine ? 0 : 40,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: message.isPostShare
                ? ChatPostShareBubble(
                    message: message,
                    background: background,
                    textColor: textColor,
                    metaColor: metaColor,
                    borderRadius: borderRadius,
                    timeLabel: timeLabel,
                    isMine: isMine,
                    bubbleDecoration: _bubbleDecoration,
                    timeRow: (time, meta, mine, msg) => _TimeRow(
                      timeLabel: time,
                      metaColor: meta,
                      isMine: mine,
                      message: msg,
                    ),
                  )
                : _TextBubble(
                    message: message,
                    background: background,
                    textColor: textColor,
                    metaColor: metaColor,
                    borderRadius: borderRadius,
                    timeLabel: timeLabel,
                    isMine: isMine,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.background,
    required this.textColor,
    required this.metaColor,
    required this.borderRadius,
    required this.timeLabel,
    required this.isMine,
  });

  final ChatMessage message;
  final Color background;
  final Color textColor;
  final Color metaColor;
  final BorderRadius borderRadius;
  final String timeLabel;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: DecoratedBox(
        decoration: _bubbleDecoration(background, borderRadius, isMine),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message.text,
                style: AppTextStyle.base(15, color: textColor, height: 1.35),
              ),
              const SizedBox(height: 4),
              _TimeRow(timeLabel: timeLabel, metaColor: metaColor, isMine: isMine, message: message),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _bubbleDecoration(Color background, BorderRadius borderRadius, bool isMine) {
  return BoxDecoration(
    color: background,
    borderRadius: borderRadius,
    border: isMine ? null : Border.all(color: AppColors.border.withValues(alpha: 0.75)),
    boxShadow: [
      BoxShadow(
        color: (isMine ? AppColors.shadowPrimary : AppColors.shadowDark).withValues(alpha: 0.1),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.timeLabel,
    required this.metaColor,
    required this.isMine,
    required this.message,
  });

  final String timeLabel;
  final Color metaColor;
  final bool isMine;
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
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
    );
  }
}
