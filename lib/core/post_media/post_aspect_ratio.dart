import 'package:clover/core/post_media/post_media_constants.dart';

/// Плитка в сетке: [cross] колонок × [main] строк (базовая ячейка — квадрат).
typedef PostGridSpan = ({int cross, int main});

/// Форматы медиа поста. Маркер в URL / Storage: `…__ar-4x3…`.
enum PostAspectRatio {
  square1x1(1, 1, '1:1'),
  standard4x3(4, 3, '4:3'),
  landscape16x9(16, 9, '16:9'),
  portrait9x16(9, 16, '9:16');

  const PostAspectRatio(this.width, this.height, this.label);

  final int width;
  final int height;
  final String label;

  double get ratio => width / height;

  String get marker => '${width}x$height';

  /// Маркер в имени файла Storage: `…__ar-4x3.jpg`.
  String get storageMarker => '__ar-$marker';

  /// Сколько строк занимает плитка при заданной ширине в колонках сетки.
  int gridMainAxisCells(int cross) {
    final main = (cross / ratio).round();
    return main.clamp(1, cross * 4);
  }

  /// Span плитки в staggered-сетке.
  PostGridSpan gridSpan({
    required int gridCrossAxisCount,
    bool useFullRowForLandscape = false,
  }) {
    final half = gridCrossAxisCount ~/ 2;

    return switch (this) {
      PostAspectRatio.square1x1 || PostAspectRatio.standard4x3 => (
        cross: half,
        main: gridMainAxisCells(half),
      ),
      PostAspectRatio.portrait9x16 => (
        cross: half,
        main: gridMainAxisCells(half),
      ),
      PostAspectRatio.landscape16x9 when useFullRowForLandscape => (
        cross: gridCrossAxisCount,
        main: gridMainAxisCells(gridCrossAxisCount),
      ),
      PostAspectRatio.landscape16x9 => (
        cross: half,
        main: gridMainAxisCells(half),
      ),
    };
  }

  /// Высота контейнера медиа на экране поста.
  double detailHeightForWidth(double width, double screenHeight) {
    final natural = width / ratio;

    if (this == PostAspectRatio.portrait9x16) {
      final maxHeight = screenHeight * PostMediaConstants.portraitDetailMaxHeightFraction;
      return natural.clamp(width * 0.9, maxHeight);
    }

    return natural;
  }

  static final _aspectRe = RegExp(r'__ar-(\d+)x(\d+)', caseSensitive: false);

  static PostAspectRatio fromMarker(String? marker) {
    if (marker == null || marker.trim().isEmpty) {
      return PostAspectRatio.square1x1;
    }

    final normalized = marker.trim().toLowerCase().replaceAll(':', 'x');
    for (final ratio in PostAspectRatio.values) {
      if (ratio.marker == normalized) return ratio;
    }

    return PostAspectRatio.square1x1;
  }

  static PostAspectRatio fromUrl(String url) {
    if (url.trim().isEmpty) return PostAspectRatio.square1x1;

    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    final match = _aspectRe.firstMatch(path);
    if (match == null) return PostAspectRatio.square1x1;

    final width = int.tryParse(match.group(1) ?? '');
    final height = int.tryParse(match.group(2) ?? '');
    if (width == null || height == null || width <= 0 || height <= 0) {
      return PostAspectRatio.square1x1;
    }

    return fromMarker('${width}x$height');
  }
}
