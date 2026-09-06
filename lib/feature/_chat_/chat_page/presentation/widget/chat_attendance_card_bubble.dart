import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_attendance_card.dart';
import 'package:flutter/material.dart';

/// Accept / Reject invite or Ack rules — bubble card in chat.
class ChatAttendanceCardBubble extends StatefulWidget {
  const ChatAttendanceCardBubble({super.key, required this.card, required this.isMine});

  final ChatAttendanceCard card;
  final bool isMine;

  @override
  State<ChatAttendanceCardBubble> createState() => _ChatAttendanceCardBubbleState();
}

class _ChatAttendanceCardBubbleState extends State<ChatAttendanceCardBubble> {
  bool _busy = false;
  bool _done = false;
  String? _doneLabel;

  Future<void> _run(Future<void> Function() action, String okLabel) async {
    if (_busy || _done) return;
    setState(() => _busy = true);
    try {
      await action();
      await sl<AttendanceContextStore>().refreshRemote();
      if (!mounted) return;
      setState(() {
        _done = true;
        _doneLabel = okLabel;
      });
      AppSnackBar.show(context, message: okLabel, kind: AppSnackBarKind.success);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось выполнить';
      AppSnackBar.show(context, message: msg, kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final title = widget.card.isInvite ? 'Приглашение в команду' : 'Правила компании';
    final subtitle = widget.card.isInvite
        ? 'Стать частью «${widget.card.workplaceName}»'
        : '«${widget.card.workplaceName}» · v${widget.card.configVersion ?? 1}';

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
          Text(title, style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyle.base(13, color: colors.subTextColor)),
          if (_done) ...[
            const SizedBox(height: 12),
            Text(_doneLabel ?? 'Готово', style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w600)),
          ] else if (!widget.isMine) ...[
            const SizedBox(height: 12),
            if (widget.card.isInvite) ...[
              AttendancePrimaryButton(
                text: _busy ? '…' : 'Принять',
                height: 44,
                isExpanded: true,
                interactive: !_busy,
                onTap: () {
                  final mid = widget.card.membershipId;
                  if (mid == null || mid.isEmpty) return;
                  _run(() => sl<AttendanceRemoteRepository>().acceptInvite(mid), 'Вы в команде');
                },
              ),
              const SizedBox(height: 8),
              AppOutlinedButton(
                text: 'Отклонить',
                height: 44,
                isExpanded: true,
                service: kAttendanceService,
                onTap: () {
                  final mid = widget.card.membershipId;
                  if (mid == null || mid.isEmpty) return;
                  _run(() => sl<AttendanceRemoteRepository>().rejectInvite(mid), 'Приглашение отклонено');
                },
              ),
            ] else ...[
              AttendancePrimaryButton(
                text: _busy ? '…' : 'Принять правила',
                height: 44,
                isExpanded: true,
                interactive: !_busy,
                onTap: () => _run(
                  () => sl<AttendanceRemoteRepository>().ackConfig(widget.card.workplaceId),
                  'Правила приняты',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
