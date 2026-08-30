import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool isEnabled;

  const AppField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.validator,
    this.inputFormatters,
    this.isEnabled = true,
  });

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.isEnabled;

    final borderColor = _isFocused ? colors.fieldBorderFocused : colors.fieldBorder;
    final bgColor = enabled ? colors.fieldBackground : colors.fieldBackgroundDisabled;
    final textColor = enabled ? colors.fieldText : colors.fieldTextDisabled;
    final iconColor = _isFocused ? colors.fieldIconFocused : colors.fieldIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              widget.labelText!,
              style: AppTextStyle.base(
                13,
                fontWeight: FontWeight.w600,
                color: _isFocused ? colors.fieldLabelFocused : colors.fieldLabel,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: _isFocused ? 1.6 : 1.0),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: colors.fieldShadowFocused.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colors.shadowDark.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: enabled,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            validator: widget.validator,
            inputFormatters: widget.inputFormatters,
            style: AppTextStyle.base(16, fontWeight: FontWeight.w500, color: textColor),
            cursorColor: colors.fieldCursor,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTextStyle.base(16, fontWeight: FontWeight.w400, color: colors.fieldHint),
              prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: iconColor, size: 22) : null,
              suffixIcon: widget.suffixIcon != null
                  ? IconTheme(data: IconThemeData(color: iconColor), child: widget.suffixIcon!)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
