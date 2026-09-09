/// Геометрия чата: compact rounded conversational UI.
///
/// Цвета — только через [AppColors] / `context.colors`.
/// См. [docs/code/ui/chat-conversational-geometry.md].
abstract final class ChatGeometry {
  ChatGeometry._();

  /// Основной bubble (WA-like soft).
  static const double bubbleRadius = 17;

  /// Хвост у края (ближе к собеседнику / себе).
  static const double bubbleTailRadius = 6;

  /// Вложенный reply / quote.
  static const double replyRadius = 12;

  /// Pill у поля ввода.
  static const double inputRadius = 26;

  /// Круглые контролы (+ / send).
  static const double controlSize = 44;

  static const double smallControlRadius = 12;

  /// Плотный ритм между сообщениями.
  static const double messageGap = 6;

  static const double listHorizontalPadding = 10;

  static const double bubbleMaxWidthFactor = 0.78;

  static const double replyAccentWidth = 3;
}
