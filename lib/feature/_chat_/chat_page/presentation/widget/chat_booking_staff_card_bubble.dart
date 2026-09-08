import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_booking_staff_card.dart';
import 'package:flutter/material.dart';

/// Accept / Reject booking staff invite — bubble card in chat.
class ChatBookingStaffCardBubble extends StatefulWidget {
  const ChatBookingStaffCardBubble({super.key, required this.card, required this.isMine});

  final ChatBookingStaffCard card;
  final bool isMine;

  @override
  State<ChatBookingStaffCardBubble> createState() => _ChatBookingStaffCardBubbleState();
}

class _ChatBookingStaffCardBubbleState extends State<ChatBookingStaffCardBubble> {
  bool _busy = false;
  bool _done = false;
  String? _doneLabel;

  Future<void> _run(Future<void> Function() action, String okLabel) async {
    if (_busy || _done) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _done = true;
        _doneLabel = okLabel;
      });
      AppSnackBar.show(context, message: okLabel, kind: AppSnackBarKind.success);
    } catch (e) {
      if (!mounted) return;
      final msg = e is BookingException ? e.userMessage : 'Не удалось выполнить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Приглашение в запись',
            style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Стать исполнителем · «${widget.card.hostDisplayName}»',
            style: AppTextStyle.base(13, color: colors.subTextColor),
          ),
          if (_done) ...[
            const SizedBox(height: 12),
            Text(
              _doneLabel ?? 'Готово',
              style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w600),
            ),
          ] else if (!widget.isMine) ...[
            const SizedBox(height: 12),
            BookingPrimaryButton(
              text: _busy ? '…' : 'Принять',
              height: 44,
              isExpanded: true,
              interactive: !_busy,
              onTap: () => _run(
                () => sl<BookingStaffRepository>().acceptInvite(widget.card.inviteId),
                'Вы исполнитель',
              ),
            ),
            const SizedBox(height: 8),
            AppOutlinedButton(
              text: 'Отклонить',
              height: 44,
              isExpanded: true,
              service: kBookingService,
              onTap: () => _run(
                () => sl<BookingStaffRepository>().rejectInvite(widget.card.inviteId),
                'Приглашение отклонено',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
