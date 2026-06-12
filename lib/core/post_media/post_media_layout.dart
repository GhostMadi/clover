import 'package:clover/core/post_media/post_aspect_ratio.dart';
import 'package:clover/core/post_media/post_media_constants.dart';

/// Общие константы и раскладка контейнеров медиа поста.
abstract final class PostMediaLayout {
  PostMediaLayout._();

  /// Staggered-сетка: 6 колонок → 2 визуальные колонки по 3 ячейки.
  static const int gridCrossAxisCount = PostMediaConstants.gridCrossAxisCount;

  /// Макс. высота вертикального поста на экране деталей (доля экрана).
  static const double portraitDetailMaxHeightFraction = PostMediaConstants.portraitDetailMaxHeightFraction;

  /// Превью в селекторе фото (шаг выбора).
  static final double selectorPreviewAspectRatio = PostAspectRatio.standard4x3.ratio;

  /// Раскладка сетки профиля / ленты по форматам обложек.
  ///
  /// - 1×1 — 3×3 (квадрат);
  /// - 4×3 — 3×2 (альбомный);
  /// - 9×16 — 3×5 (вертикальный);
  /// - 16×9 — 6×3 на всю ширину, иначе 3×2.
  static List<PostGridSpan> computeGridSpans(
    List<PostAspectRatio> aspects, {
    int crossAxisCount = gridCrossAxisCount,
  }) {
    final n = crossAxisCount.clamp(2, 12);
    final colTop = List<int>.filled(n, 0);
    final out = <PostGridSpan>[];

    int placementTop(int startCol, int cross) {
      var top = colTop[startCol];
      for (var i = startCol + 1; i < startCol + cross; i++) {
        if (colTop[i] > top) top = colTop[i];
      }
      return top;
    }

    int leftmostColForSpan(int cross) {
      var bestCol = 0;
      var bestTop = 1 << 30;
      for (var c = 0; c <= n - cross; c++) {
        final top = placementTop(c, cross);
        if (top < bestTop) {
          bestTop = top;
          bestCol = c;
        }
      }
      return bestCol;
    }

    void occupySpan(PostGridSpan span, int startCol) {
      out.add(span);
      final newTop = placementTop(startCol, span.cross) + span.main;
      for (var c = startCol; c < startCol + span.cross; c++) {
        colTop[c] = newTop;
      }
    }

    final half = n ~/ 2;

    for (final aspect in aspects) {
      if (aspect == PostAspectRatio.landscape16x9) {
        final fullSpan = aspect.gridSpan(gridCrossAxisCount: n, useFullRowForLandscape: true);
        final halfSpan = aspect.gridSpan(gridCrossAxisCount: n);
        final fullTop = placementTop(0, n);
        final halfCol = leftmostColForSpan(half);
        final halfTop = placementTop(halfCol, half);

        if (fullTop <= halfTop) {
          occupySpan(fullSpan, 0);
        } else {
          occupySpan(halfSpan, halfCol);
        }
        continue;
      }

      final span = aspect.gridSpan(gridCrossAxisCount: n);
      final col = leftmostColForSpan(span.cross);
      occupySpan(span, col);
    }

    return out;
  }
}
