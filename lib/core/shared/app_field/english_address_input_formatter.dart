import 'package:flutter/services.dart';

/// Только латиница и символы адреса (цифры, пробел, запятая и т.д.).
class EnglishAddressInputFormatter extends TextInputFormatter {
  const EnglishAddressInputFormatter();
  static final RegExp _allowed = RegExp(r"[a-zA-Z0-9\s,.\-/'#()]");

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final buffer = StringBuffer();
    for (final rune in newValue.text.runes) {
      final char = String.fromCharCode(rune);
      if (_allowed.hasMatch(char)) {
        buffer.write(char);
      }
    }

    final filtered = buffer.toString();
    if (filtered == newValue.text) return newValue;

    var selectionIndex = filtered.length;
    for (var i = 0; i < newValue.selection.end && i < filtered.length; i++) {
      selectionIndex = i + 1;
    }

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: selectionIndex.clamp(0, filtered.length)),
    );
  }
}
