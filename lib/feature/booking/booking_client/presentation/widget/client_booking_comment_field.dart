import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

/// Комментарий клиента к записи — необязательное многострочное поле.
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
    final borderColor = _isFocused ? AppColors.fieldBorderFocused : AppColors.fieldBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Комментарий',
            style: AppTextStyle.base(
              13,
              fontWeight: FontWeight.w600,
              color: _isFocused ? AppColors.fieldLabelFocused : AppColors.fieldLabel,
            ),
          ),
        ),
        Text(
          'Необязательно — пожелания к услуге или уточнения для мастера',
          style: AppTextStyle.base(12, color: AppColors.subTextColor, height: 1.3),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: _isFocused ? 1.6 : 1),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.fieldShadowFocused.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.shadowDark.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: 4,
            minLines: 3,
            maxLength: widget.maxLength,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyle.base(16, fontWeight: FontWeight.w500, color: AppColors.fieldText, height: 1.4),
            cursorColor: AppColors.fieldCursor,
            decoration: InputDecoration(
              hintText: 'Например: коротко сбоку, без фейда',
              hintStyle: AppTextStyle.base(16, fontWeight: FontWeight.w400, color: AppColors.fieldHint),
              border: InputBorder.none,
              counterStyle: AppTextStyle.base(12, color: AppColors.subTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
