import 'dart:math' as math;
import 'dart:ui';

/// Математика кадрирования: фото всегда заполняет рамку, pan/zoom не выходят за границы.
abstract final class AppImageCropMath {
  static const double minUserScale = 1;
  static const double maxUserScale = 4;

  static double coverScale({
    required double viewportWidth,
    required double viewportHeight,
    required double imageWidth,
    required double imageHeight,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0) return 1;
    return math.max(viewportWidth / imageWidth, viewportHeight / imageHeight);
  }

  static ({double width, double height}) renderSize({
    required double viewportWidth,
    required double viewportHeight,
    required double imageWidth,
    required double imageHeight,
    required double userScale,
  }) {
    final base = coverScale(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    final scale = clampUserScale(userScale);
    return (
      width: imageWidth * base * scale,
      height: imageHeight * base * scale,
    );
  }

  static double clampUserScale(double scale) => scale.clamp(minUserScale, maxUserScale);

  static Offset clampOffset({
    required Offset offset,
    required double viewportWidth,
    required double viewportHeight,
    required double imageWidth,
    required double imageHeight,
    required double userScale,
  }) {
    final render = renderSize(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      userScale: userScale,
    );

    final maxDx = math.max(0, (render.width - viewportWidth) / 2);
    final maxDy = math.max(0, (render.height - viewportHeight) / 2);

    return Offset(
      offset.dx.clamp(-maxDx, maxDx).toDouble(),
      offset.dy.clamp(-maxDy, maxDy).toDouble(),
    );
  }

  static ({double scale, Offset offset}) clampTransform({
    required double userScale,
    required Offset offset,
    required double viewportWidth,
    required double viewportHeight,
    required double imageWidth,
    required double imageHeight,
  }) {
    final scale = clampUserScale(userScale);
    final clampedOffset = clampOffset(
      offset: offset,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      userScale: scale,
    );

    return (scale: scale, offset: clampedOffset);
  }
}
