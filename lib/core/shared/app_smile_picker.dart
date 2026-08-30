import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_field/emoji_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Поле для emoji + горизонтальная лента быстрого выбора.
class AppSmilePicker extends StatefulWidget {
  const AppSmilePicker({
    super.key,
    this.controller,
    this.label,
    this.hintText = 'Выберите или введите эмодзи',
    this.maxLength = 1,
    this.onChanged,
    this.enabled = true,
    this.emojis,
    this.shuffleStrip = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String hintText;
  final int maxLength;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final List<String>? emojis;
  final bool shuffleStrip;

  static const defaultEmojis = <String>[
    '😀',
    '😁',
    '😂',
    '🤣',
    '😊',
    '😍',
    '🥰',
    '😎',
    '🤩',
    '🥳',
    '😇',
    '🤗',
    '🤔',
    '😴',
    '😭',
    '😡',
    '👍',
    '👏',
    '🙌',
    '💪',
    '🤝',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '✨',
    '🔥',
    '⭐',
    '🌟',
    '💫',
    '🎉',
    '🎈',
    '🎵',
    '🎶',
    '📍',
    '🗺️',
    '☀️',
    '🌈',
    '🌸',
    '🍀',
    '🌿',
    '🍕',
    '☕',
    '🍻',
    '⚽',
    '🏀',
    '🎯',
    '💡',
    '📸',
    '🛍️',
    '💼',
    '🚀',
    '💎',
    '🪩',
    '🎭',
    '🎨',
    '🎬',
    '🎤',
    '🎧',
    '🎮',
    '🃏',
    '🎲',
    '🦄',
    '🐶',
    '🐱',
    '🦋',
    '🌙',
  ];

  @override
  State<AppSmilePicker> createState() => _AppSmilePickerState();
}

class _AppSmilePickerState extends State<AppSmilePicker> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  late final List<String> _emojis;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _emojis = List<String>.from(widget.emojis ?? AppSmilePicker.defaultEmojis);
    if (widget.shuffleStrip) {
      _emojis.shuffle();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  int get _emojiCount => _controller.text.characters.length;

  bool get _canAddMore => _emojiCount < widget.maxLength;

  /// Лента активна: можно выбрать или заменить emoji.
  bool get _canPickFromStrip => widget.enabled && (widget.maxLength <= 1 || _canAddMore);

  void _insertEmoji(String emoji) {
    if (!widget.enabled) return;

    if (widget.maxLength <= 1) {
      _controller.value = TextEditingValue(
        text: emoji,
        selection: TextSelection.collapsed(offset: emoji.length),
        composing: TextRange.empty,
      );
      widget.onChanged?.call(emoji);
      HapticFeedback.selectionClick();
      setState(() {});
      return;
    }

    if (!_canAddMore) return;

    final value = _controller.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final next = text.replaceRange(start, end, emoji);

    if (next.characters.length > widget.maxLength) return;

    _controller.value = value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: start + emoji.length),
      composing: TextRange.empty,
    );

    widget.onChanged?.call(next);
    HapticFeedback.selectionClick();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppField(
          controller: _controller,
          labelText: widget.label,
          hintText: widget.hintText,
          textInputAction: TextInputAction.done,
          isEnabled: widget.enabled,
          onChanged: (value) {
            widget.onChanged?.call(value);
            setState(() {});
          },
          inputFormatters: [EmojiInputFormatter(maxLength: widget.maxLength)],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: _emojis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final emoji = _emojis[index];
              final canTap = _canPickFromStrip;

              return _EmojiChip(emoji: emoji, enabled: canTap, onTap: () => _insertEmoji(emoji));
            },
          ),
        ),
      ],
    );
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({required this.emoji, required this.enabled, required this.onTap});

  final String emoji;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: enabled ? colors.surfaceSoft : colors.fieldBackgroundDisabled,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? colors.borderSoft : colors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Text(emoji, style: AppTextStyle.base(26, height: 1)),
        ),
      ),
    );
  }
}
