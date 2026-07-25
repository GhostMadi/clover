/// Форматирование бонусов для UI.
abstract final class BonusFormat {
  static String bonusWord(int value) {
    final mod10 = value.abs() % 10;
    final mod100 = value.abs() % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'бонусов';
    if (mod10 == 1) return 'бонус';
    if (mod10 >= 2 && mod10 <= 4) return 'бонуса';
    return 'бонусов';
  }

  static String formatBalance(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('\u00a0');
    }
    return buf.toString();
  }
}
