import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_client/presentation/widget/client_booking_step_header.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Комментарий клиента к записи — необязательное поле.
class ClientBookingCommentField extends StatefulWidget {
  const ClientBookingCommentField({
    super.key,
    required this.controller,
    this.maxLength = 300,
  });

  final TextEditingController controller;
  final int maxLength;

  @override
  State<ClientBookingCommentField> createState() => _ClientBookingCommentFieldState();
}

class _ClientBookingCommentFieldState extends State<ClientBookingCommentField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final borderColor = _isFocused ? accent.ctaBorder : context.colors.border.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClientBookingStepHeader(
          step: 5,
          title: 'Комментарий',
          subtitle: 'Необязательно — пожелания мастеру',
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: _isFocused ? 1.4 : 1),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: 3,
            minLines: 2,
            maxLength: widget.maxLength,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyle.base(15, fontWeight: FontWeight.w500, color: context.colors.textColor, height: 1.35),
            cursorColor: accent.icon,
            decoration: InputDecoration(
              hintText: 'Например: коротко сбоку',
              hintStyle: AppTextStyle.base(15, fontWeight: FontWeight.w400, color: context.colors.subTextColor),
              border: InputBorder.none,
              counterStyle: AppTextStyle.base(11, color: context.colors.iconMuted),
              contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            ),
          ),
        ),
      ],
    );
  }
}
