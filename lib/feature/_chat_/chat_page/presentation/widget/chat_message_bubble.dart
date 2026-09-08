import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/form/chat_time_formatting.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_attachment_bubble.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_attendance_card_bubble.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_booking_staff_card_bubble.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_post_ref_preview.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_reactions_row.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_reply_quote.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onReactionToggle,
  });

  final ChatMessage message;
  final ValueChanged<String>? onReactionToggle;

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

    final background = isMine ? context.colors.primary : context.colors.surface;
    final textColor = isMine ? context.colors.white : context.colors.textColor;
    final metaColor = isMine ? context.colors.white.withValues(alpha: 0.82) : context.colors.subTextColor;

    final borderRadius = _radius.copyWith(
      bottomRight: isMine ? const Radius.circular(8) : _radius.bottomRight,
      bottomLeft: isMine ? _radius.bottomLeft : const Radius.circular(8),
    );

    final colors = context.colors;
    final reactions = message.hasReactions
        ? ChatReactionsRow(
            reactions: message.reactions,
            isMine: isMine,
            onReactionTap: onReactionToggle,
          )
        : null;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: _buildBody(
        context,
        colors: colors,
        background: background,
        textColor: textColor,
        metaColor: metaColor,
        borderRadius: borderRadius,
        timeLabel: timeLabel,
        isMine: isMine,
        reactions: reactions,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required AppPalette colors,
    required Color background,
    required Color textColor,
    required Color metaColor,
    required BorderRadius borderRadius,
    required String timeLabel,
    required bool isMine,
    required Widget? reactions,
  }) {
    if (message.isAttendanceCard && message.attendanceCard != null) {
      return ChatAttendanceCardBubble(card: message.attendanceCard!, isMine: isMine);
    }

    if (message.isBookingStaffCard && message.bookingStaffCard != null) {
      return ChatBookingStaffCardBubble(card: message.bookingStaffCard!, isMine: isMine);
    }

    if (message.isPostShare) {
      return Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatPostShareBubble(
            message: message,
            background: background,
            textColor: textColor,
            metaColor: metaColor,
            borderRadius: borderRadius,
            timeLabel: timeLabel,
            isMine: isMine,
            bubbleDecoration: (bg, radius, mine) => _bubbleDecoration(colors, bg, radius, mine),
            timeRow: (time, meta, mine, msg) => _TimeRow(
              timeLabel: time,
              metaColor: meta,
              isMine: mine,
              message: msg,
            ),
          ),
          if (reactions != null) ...[
            const SizedBox(height: 4),
            reactions,
          ],
        ],
      );
    }

    if (message.isMedia || message.isFile) {
      return ChatAttachmentBubble(
        message: message,
        background: background,
        textColor: textColor,
        metaColor: metaColor,
        borderRadius: borderRadius,
        timeLabel: timeLabel,
        isMine: isMine,
        reactions: reactions,
      );
    }

    return Column(
      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _TextBubble(
          message: message,
          background: background,
          textColor: textColor,
          metaColor: metaColor,
          borderRadius: borderRadius,
          timeLabel: timeLabel,
          isMine: isMine,
        ),
        if (reactions != null) ...[
          const SizedBox(height: 4),
          reactions,
        ],
      ],
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
        decoration: _bubbleDecoration(context.colors, background, borderRadius, isMine),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message.hasReply && message.replyPreview != null)
                ChatReplyQuote(
                  preview: message.replyPreview!,
                  textColor: textColor,
                  accentColor: isMine ? context.colors.white : context.colors.primary,
                ),
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

BoxDecoration _bubbleDecoration(AppPalette colors, Color background, BorderRadius borderRadius, bool isMine) {
  return BoxDecoration(
    color: background,
    borderRadius: borderRadius,
    border: isMine ? null : Border.all(color: colors.border.withValues(alpha: 0.75)),
    boxShadow: [
      BoxShadow(
        color: (isMine ? colors.shadowPrimary : colors.shadowDark).withValues(alpha: 0.1),
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
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            Text(
              'изм.',
              style: AppTextStyle.base(10, color: metaColor, fontWeight: FontWeight.w600),
            ),
          ],
          if (isMine) ...[
            const SizedBox(width: 4),
            Icon(
              message.isPending
                  ? AppIcons.schedule.icon
                  : (message.isRead ? AppIcons.doneAll.icon : AppIcons.done.icon),
              size: 14,
              color: metaColor,
            ),
          ],
        ],
      ),
    );
  }
}
