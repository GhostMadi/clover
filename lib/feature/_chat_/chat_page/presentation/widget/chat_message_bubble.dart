import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/form/chat_time_formatting.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_attachment_bubble.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_attendance_card_bubble.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_booking_staff_card_bubble.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_post_ref_preview.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_geometry.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_peer_accent.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_reactions_row.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_reply_quote.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_structured_card_shell.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.peerAccent,
    this.onReactionToggle,
  });

  final ChatMessage message;
  final ChatPeerAccent? peerAccent;
  final ValueChanged<String>? onReactionToggle;

  static BorderRadius get _radius => BorderRadius.all(Radius.circular(ChatGeometry.bubbleRadius));

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final timeLabel = ChatTimeFormatting.format(message.sentAt);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxFactor = ChatGeometry.bubbleMaxWidthFactor;
    final maxWidth = message.isPostShare
        ? (ChatPostRefPreview.width + 28).clamp(0.0, screenWidth * maxFactor)
        : screenWidth * maxFactor;

    final colors = context.colors;
    final accent = isMine
        ? ChatPeerAccent.mine(colors)
        : (peerAccent ?? ChatPeerAccent.forSeed(colors, message.id));

    final background = accent.fill;
    final textColor = accent.onFill;
    final metaColor = accent.meta;
    final replyAccent = accent.ink;

    final tail = Radius.circular(ChatGeometry.bubbleTailRadius);
    final borderRadius = _radius.copyWith(
      bottomRight: isMine ? tail : _radius.bottomRight,
      bottomLeft: isMine ? _radius.bottomLeft : tail,
    );

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
        replyAccent: replyAccent,
        accentBorder: accent.border,
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
    required Color replyAccent,
    required Color? accentBorder,
    required BorderRadius borderRadius,
    required String timeLabel,
    required bool isMine,
    required Widget? reactions,
  }) {
    if (message.isAttendanceCardKind) {
      if (message.attendanceCard != null) {
        return ChatAttendanceCardBubble(card: message.attendanceCard!, isMine: isMine);
      }
      return ChatStructuredCardShell(
        title: message.kind == 'attendance_rules' ? 'Правила компании' : 'Приглашение в команду',
        subtitle: message.text.isNotEmpty ? message.text : null,
      );
    }

    if (message.isBookingStaffCardKind) {
      if (message.bookingStaffCard != null) {
        return ChatBookingStaffCardBubble(card: message.bookingStaffCard!, isMine: isMine);
      }
      return ChatStructuredCardShell(
        title: 'Приглашение в запись',
        subtitle: message.text.isNotEmpty ? message.text : null,
      );
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
            bubbleDecoration: (bg, radius, mine) =>
                _bubbleDecoration(colors, bg, radius, mine, accentBorder: accentBorder),
            timeRow: (time, meta, mine, msg) => _TimeRow(
              timeLabel: time,
              metaColor: meta,
              tickColor: replyAccent,
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
          replyAccent: replyAccent,
          accentBorder: accentBorder,
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
    required this.replyAccent,
    required this.accentBorder,
    required this.borderRadius,
    required this.timeLabel,
    required this.isMine,
  });

  final ChatMessage message;
  final Color background;
  final Color textColor;
  final Color metaColor;
  final Color replyAccent;
  final Color? accentBorder;
  final BorderRadius borderRadius;
  final String timeLabel;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: DecoratedBox(
        decoration: _bubbleDecoration(
          context.colors,
          background,
          borderRadius,
          isMine,
          accentBorder: accentBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (message.hasReply && message.replyPreview != null)
                ChatReplyQuote(
                  preview: message.replyPreview!,
                  textColor: textColor,
                  accentColor: replyAccent,
                ),
              Text(
                message.text,
                style: AppTextStyle.base(15, color: textColor, height: 1.3),
              ),
              const SizedBox(height: 3),
              _TimeRow(
                timeLabel: timeLabel,
                metaColor: metaColor,
                tickColor: replyAccent,
                isMine: isMine,
                message: message,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _bubbleDecoration(
  AppPalette colors,
  Color background,
  BorderRadius borderRadius,
  bool isMine, {
  Color? accentBorder,
}) {
  return BoxDecoration(
    color: background,
    borderRadius: borderRadius,
    border: Border.all(
      color: (accentBorder ?? colors.border).withValues(alpha: isMine ? 0.9 : 0.55),
    ),
    boxShadow: [
      BoxShadow(
        color: colors.shadowDark.withValues(alpha: 0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
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
    this.tickColor,
  });

  final String timeLabel;
  final Color metaColor;
  final Color? tickColor;
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
              color: tickColor ?? metaColor,
            ),
          ],
        ],
      ),
    );
  }
}
