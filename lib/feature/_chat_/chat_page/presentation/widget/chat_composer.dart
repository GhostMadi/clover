import 'dart:ui';
import 'package:clover/core/resources/app_icons.dart';

import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:flutter/material.dart';

enum ChatAttachmentAction { photo, document }

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachmentSelected,
    this.isSending = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<ChatAttachmentAction>? onAttachmentSelected;
  final bool isSending;

  static const double _barRadius = 28;
  static const double _horizontalMargin = 16;
  static const double _bottomMargin = 12;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      _hasText = widget.controller.text.trim().isNotEmpty;
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (next == _hasText) return;
    setState(() => _hasText = next);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final canSend = _hasText && !widget.isSending;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        ChatComposer._horizontalMargin,
        0,
        ChatComposer._horizontalMargin,
        bottomInset > 0 ? 8 : ChatComposer._bottomMargin + bottomSafe,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ChatComposer._barRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(ChatComposer._barRadius),
              border: Border.all(color: context.colors.border.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadowDark.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: context.colors.shadowPrimary.withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onAttachmentSelected != null) ...[
                    AppMiniMenu<ChatAttachmentAction>(
                      menuTooltip: 'Вложение',
                      items: [
                        AppMiniMenuItem(
                          value: ChatAttachmentAction.photo,
                          title: 'Фото',
                          icon: AppIcons.imageOutlined.icon,
                        ),
                        AppMiniMenuItem(
                          value: ChatAttachmentAction.document,
                          title: 'Документ',
                          icon: AppIcons.description.icon,
                        ),
                      ],
                      onSelected: widget.onAttachmentSelected!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.addRounded.icon,
                          size: 24,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      style: AppTextStyle.base(16, color: context.colors.textColor, height: 1.35),
                      cursorColor: context.colors.fieldCursor,
                      decoration: InputDecoration(
                        hintText: 'Сообщение',
                        hintStyle: AppTextStyle.base(16, color: context.colors.subTextColor),
                        filled: true,
                        fillColor: context.colors.surfaceSoft.withValues(alpha: 0.65),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: context.colors.primary.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: canSend ? context.colors.primary : context.colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: canSend
                          ? [
                              BoxShadow(
                                color: context.colors.shadowPrimary.withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: canSend ? widget.onSend : null,
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: widget.isSending
                              ? Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.colors.white,
                                  ),
                                )
                              : Icon(
                                  AppIcons.send.icon,
                                  color: canSend ? context.colors.white : context.colors.iconMuted,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
