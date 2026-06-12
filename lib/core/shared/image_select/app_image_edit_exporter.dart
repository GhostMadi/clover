import 'dart:io';
import 'dart:typed_data';

import 'package:clover/core/shared/image_select/app_image_crop_math.dart';
import 'package:clover/core/shared/image_select/app_image_edit_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

/// Экспорт отредактированного фото в JPEG: crop, формат и цветовые фильтры.
abstract final class AppImageEditExporter {
  static const int defaultMaxWidth = 2048;

  static Future<Uint8List> exportJpegBytes({
    required File sourceFile,
    required AppImageEditSettings settings,
    int imageWidth = 0,
    int imageHeight = 0,
    int maxOutputWidth = defaultMaxWidth,
    int jpegQuality = 88,
  }) async {
    final source = await _decodeSource(sourceFile);
    final oriented = img.bakeOrientation(source);

    final srcW = imageWidth > 0 ? imageWidth : oriented.width;
    final srcH = imageHeight > 0 ? imageHeight : oriented.height;

    final outputSize = _outputSize(
      aspectRatio: settings.aspectRatio.ratio,
      maxOutputWidth: maxOutputWidth,
    );

    final cropped = _renderViewport(
      source: oriented,
      settings: settings,
      outputWidth: outputSize.width,
      outputHeight: outputSize.height,
      sourceWidth: srcW,
      sourceHeight: srcH,
    );

    _applyColorMatrix(cropped, settings.composedColorMatrix);

    final encoded = img.encodeJpg(cropped, quality: jpegQuality);
    return Uint8List.fromList(encoded);
  }

  static Future<img.Image> _decodeSource(File sourceFile) async {
    var bytes = await sourceFile.readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded != null) return decoded;

    bytes = await FlutterImageCompress.compressWithList(bytes, format: CompressFormat.jpeg);
    decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Не удалось декодировать изображение');
    }
    return decoded;
  }

  static ({int width, int height}) _outputSize({
    required double aspectRatio,
    required int maxOutputWidth,
  }) {
    var width = maxOutputWidth;
    var height = (width / aspectRatio).round();
    if (height > maxOutputWidth) {
      height = maxOutputWidth;
      width = (height * aspectRatio).round();
    }
    return (width: width, height: height);
  }

  static img.Image _renderViewport({
    required img.Image source,
    required AppImageEditSettings settings,
    required int outputWidth,
    required int outputHeight,
    required int sourceWidth,
    required int sourceHeight,
  }) {
    final outW = outputWidth.toDouble();
    final outH = outputHeight.toDouble();
    final srcW = sourceWidth.toDouble();
    final srcH = sourceHeight.toDouble();

    var offset = settings.cropOffset;
    final refW = settings.cropViewportWidth;
    final refH = settings.cropViewportHeight;
    if (refW > 0 && refH > 0) {
      offset = Offset(
        offset.dx * outW / refW,
        offset.dy * outH / refH,
      );
    }

    final clamped = AppImageCropMath.clampTransform(
      userScale: settings.cropScale,
      offset: offset,
      viewportWidth: outW,
      viewportHeight: outH,
      imageWidth: srcW,
      imageHeight: srcH,
    );

    final render = AppImageCropMath.renderSize(
      viewportWidth: outW,
      viewportHeight: outH,
      imageWidth: srcW,
      imageHeight: srcH,
      userScale: clamped.scale,
    );

    final imageLeft = (outW - render.width) / 2 + clamped.offset.dx;
    final imageTop = (outH - render.height) / 2 + clamped.offset.dy;

    final output = img.Image(width: outputWidth, height: outputHeight);

    for (var oy = 0; oy < outputHeight; oy++) {
      for (var ox = 0; ox < outputWidth; ox++) {
        final sx = (ox - imageLeft) / render.width * srcW;
        final sy = (oy - imageTop) / render.height * srcH;

        if (sx < 0 || sy < 0 || sx >= srcW || sy >= srcH) {
          output.setPixelRgba(ox, oy, 0, 0, 0, 255);
          continue;
        }

        final pixel = source.getPixelInterpolate(sx, sy);
        output.setPixel(ox, oy, pixel);
      }
    }

    return output;
  }

  static void _applyColorMatrix(img.Image image, List<double> matrix) {
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final a = pixel.a.toDouble();

        final nr = _clampChannel(r * matrix[0] + g * matrix[1] + b * matrix[2] + a * matrix[3] + matrix[4]);
        final ng = _clampChannel(r * matrix[5] + g * matrix[6] + b * matrix[7] + a * matrix[8] + matrix[9]);
        final nb = _clampChannel(r * matrix[10] + g * matrix[11] + b * matrix[12] + a * matrix[13] + matrix[14]);
        final na = _clampChannel(r * matrix[15] + g * matrix[16] + b * matrix[17] + a * matrix[18] + matrix[19]);

        image.setPixelRgba(x, y, nr, ng, nb, na.round());
      }
    }
  }

  static int _clampChannel(double value) => value.round().clamp(0, 255);
}
