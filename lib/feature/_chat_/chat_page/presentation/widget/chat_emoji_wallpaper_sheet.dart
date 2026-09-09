import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_chat_/chat_page/data/chat_emoji_wallpaper_store.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_emoji_wallpaper_layer.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_geometry.dart';
import 'package:flutter/material.dart';

/// Шторка: ввод смайликов → фон чата.
abstract final class ChatEmojiWallpaperSheet {
  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> initialEmojis,
    required String seed,
  }) {
    return AppBottomSheet.show<List<String>?>(
      context: context,
      title: 'Фон чата',
      contentHeight: 360,
      contentBottomSpacing: 0,
      content: _ChatEmojiWallpaperForm(
        initialEmojis: initialEmojis,
        seed: seed,
      ),
    );
  }
}

class _ChatEmojiWallpaperForm extends StatefulWidget {
  const _ChatEmojiWallpaperForm({
    required this.initialEmojis,
    required this.seed,
  });

  final List<String> initialEmojis;
  final String seed;

  @override
  State<_ChatEmojiWallpaperForm> createState() => _ChatEmojiWallpaperFormState();
}

class _ChatEmojiWallpaperFormState extends State<_ChatEmojiWallpaperForm> {
  late final TextEditingController _controller;
  late List<String> _emojis;

  @override
  void initState() {
    super.initState();
    _emojis = List<String>.from(widget.initialEmojis);
    _controller = TextEditingController(text: _emojis.join());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _emojis = ChatEmojiWallpaperStore.parseInput(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Вставь смайлики — они появятся на фоне в разных местах',
          style: AppTextStyle.base(13, color: colors.subTextColor, height: 1.3),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(ChatGeometry.replyRadius),
          child: SizedBox(
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: colors.surfaceSoft),
                ChatEmojiWallpaperLayer(
                  emojis: _emojis,
                  seed: widget.seed,
                  opacity: 0.55,
                ),
                if (_emojis.isEmpty)
                  Center(
                    child: Text(
                      'Превью фона',
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppField(
          controller: _controller,
          hintText: 'Например 🍀✨💬',
          onChanged: _onChanged,
        ),
        if (_emojis.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in _emojis)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(ChatGeometry.smallControlRadius),
                    border: Border.all(color: colors.border.withValues(alpha: 0.7)),
                  ),
                  child: Text(e, style: AppTextStyle.emoji(20)),
                ),
            ],
          ),
        ],
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                text: 'Убрать',
                onTap: () => Navigator.of(context).pop(<String>[]),
                height: 48,
                borderRadius: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(List<String>.from(_emojis)),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Сохранить',
                  style: AppTextStyle.base(15, color: colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
