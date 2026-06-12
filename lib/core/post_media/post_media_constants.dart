/// Константы раскладки медиа поста.
abstract final class PostMediaConstants {
  PostMediaConstants._();

  /// Staggered-сетка: 6 колонок → 2 визуальные колонки по 3 ячейки.
  static const int gridCrossAxisCount = 6;

  /// Макс. высота вертикального поста на экране деталей (доля экрана).
  static const double portraitDetailMaxHeightFraction = 0.72;
}
