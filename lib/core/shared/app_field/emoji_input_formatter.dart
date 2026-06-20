import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Пропускает только emoji-графемы (ввод с клавиатуры или вставка).
class EmojiInputFormatter extends TextInputFormatter {
  const EmojiInputFormatter({this.maxLength});

  final int? maxLength;

  static bool isEmojiGrapheme(String grapheme) {
    if (grapheme.isEmpty) return false;

    var hasEmoji = false;
    for (final rune in grapheme.runes) {
      if (_isEmojiRune(rune)) {
        hasEmoji = true;
        continue;
      }
      if (rune == 0xFE0F || rune == 0x200D || _isRegionalIndicator(rune)) {
        continue;
      }
      return false;
    }
    return hasEmoji;
  }

  static bool _isRegionalIndicator(int rune) => rune >= 0x1F1E6 && rune <= 0x1F1FF;

  static bool _isEmojiRune(int rune) {
    return (rune >= 0x1F300 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x26FF) ||
        (rune >= 0x2700 && rune <= 0x27BF) ||
        (rune >= 0x1F600 && rune <= 0x1F64F) ||
        (rune >= 0x1F680 && rune <= 0x1F6FF) ||
        (rune >= 0x1F900 && rune <= 0x1F9FF) ||
        rune == 0x2764 ||
        rune == 0x2665 ||
        rune == 0x2728 ||
        rune == 0x2B50;
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final buffer = StringBuffer();
    for (final grapheme in newValue.text.characters) {
      if (isEmojiGrapheme(grapheme)) {
        buffer.write(grapheme);
      }
    }

    var filtered = buffer.toString();
    if (maxLength != null && filtered.characters.length > maxLength!) {
      filtered = filtered.characters.take(maxLength!).toString();
    }

    if (filtered == newValue.text) return newValue;

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.characters.length),
    );
  }
}
