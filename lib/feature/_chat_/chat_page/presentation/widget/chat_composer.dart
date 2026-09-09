import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_geometry.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_peer_accent.dart';
import 'package:flutter/material.dart';

enum ChatAttachmentAction { photo, document }

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachmentSelected,
    this.isSending = false,
    this.onChanged,
    this.hasAttachments = false,
    this.accent,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<ChatAttachmentAction>? onAttachmentSelected;
  final bool isSending;
  final ValueChanged<String>? onChanged;
  final bool hasAttachments;
  final ChatPeerAccent? accent;

  static const double _horizontalMargin = 10;
  static const double _bottomMargin = 8;

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
    widget.onChanged?.call(widget.controller.text);
    final next = widget.controller.text.trim().isNotEmpty;
    if (next == _hasText) return;
    setState(() => _hasText = next);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final canSend = (_hasText || widget.hasAttachments) && !widget.isSending;
    final control = ChatGeometry.controlSize;
    final inputRadius = ChatGeometry.inputRadius;
    final accent = widget.accent ?? ChatPeerAccent.mine(context.colors);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        ChatComposer._horizontalMargin,
        4,
        ChatComposer._horizontalMargin,
        bottomInset > 0 ? 6 : ChatComposer._bottomMargin + bottomSafe,
      ),
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
                width: control,
                height: control,
                decoration: BoxDecoration(
                  color: accent.fill,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (accent.border ?? context.colors.border).withValues(alpha: 0.7),
                  ),
                ),
                child: Icon(
                  AppIcons.addRounded.icon,
                  size: 24,
                  color: accent.ink,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 46),
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
                  fillColor: context.colors.surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(color: context.colors.border.withValues(alpha: 0.7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(color: context.colors.border.withValues(alpha: 0.7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(inputRadius),
                    borderSide: BorderSide(
                      color: accent.ink.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: canSend ? context.colors.primary : context.colors.surfaceSoft,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: canSend ? widget.onSend : null,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: control,
                height: control,
                child: widget.isSending
                    ? Padding(
                        padding: const EdgeInsets.all(12),
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
        ],
      ),
    );
  }
}
