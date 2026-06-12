import 'package:clover/core/post_media/post_media.dart';
import 'package:clover/core/shared/image_select/app_image_crop_math.dart';
import 'package:flutter/material.dart';

/// Ручные параметры и выбранный эффект для превью/экспорта.
class AppImageEditSettings {
  AppImageEditSettings({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.fade = 0,
    this.effectId = AppImageEffect.originalId,
    this.aspectRatio = PostAspectRatio.standard4x3,
    this.cropScale = AppImageCropMath.minUserScale,
    this.cropOffset = Offset.zero,
    this.cropViewportWidth = 0,
    this.cropViewportHeight = 0,
  });

  static final none = AppImageEditSettings();

  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double fade;
  final String effectId;
  final PostAspectRatio aspectRatio;
  final double cropScale;
  final Offset cropOffset;
  final double cropViewportWidth;
  final double cropViewportHeight;

  AppImageEditSettings copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? fade,
    String? effectId,
    PostAspectRatio? aspectRatio,
    double? cropScale,
    Offset? cropOffset,
    double? cropViewportWidth,
    double? cropViewportHeight,
  }) {
    return AppImageEditSettings(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      fade: fade ?? this.fade,
      effectId: effectId ?? this.effectId,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      cropScale: cropScale ?? this.cropScale,
      cropOffset: cropOffset ?? this.cropOffset,
      cropViewportWidth: cropViewportWidth ?? this.cropViewportWidth,
      cropViewportHeight: cropViewportHeight ?? this.cropViewportHeight,
    );
  }

  List<double> get composedColorMatrix {
    final effect = AppImageEffect.byId(effectId);
    return AppImageEditColorMatrices.compose([
      effect.matrix,
      AppImageEditColorMatrices.brightness(brightness),
      AppImageEditColorMatrices.contrast(contrast),
      AppImageEditColorMatrices.saturation(saturation),
      AppImageEditColorMatrices.warmth(warmth),
      AppImageEditColorMatrices.fade(fade),
    ]);
  }

  ColorFilter get colorFilter => ColorFilter.matrix(composedColorMatrix);
}

enum AppImageEditTool {
  brightness('Яркость', Icons.brightness_6_outlined),
  contrast('Контраст', Icons.contrast_outlined),
  saturation('Насыщенность', Icons.palette_outlined),
  warmth('Теплота', Icons.wb_sunny_outlined),
  fade('Затухание', Icons.blur_on_outlined);

  const AppImageEditTool(this.label, this.icon);

  final String label;
  final IconData icon;

  double readValue(AppImageEditSettings settings) => switch (this) {
    AppImageEditTool.brightness => settings.brightness,
    AppImageEditTool.contrast => settings.contrast,
    AppImageEditTool.saturation => settings.saturation,
    AppImageEditTool.warmth => settings.warmth,
    AppImageEditTool.fade => settings.fade,
  };

  AppImageEditSettings writeValue(AppImageEditSettings settings, double value) => switch (this) {
    AppImageEditTool.brightness => settings.copyWith(brightness: value),
    AppImageEditTool.contrast => settings.copyWith(contrast: value),
    AppImageEditTool.saturation => settings.copyWith(saturation: value),
    AppImageEditTool.warmth => settings.copyWith(warmth: value),
    AppImageEditTool.fade => settings.copyWith(fade: value),
  };
}

class AppImageEffect {
  const AppImageEffect({required this.id, required this.name, required this.matrix});

  static const originalId = 'original';

  final String id;
  final String name;
  final List<double> matrix;

  static const List<AppImageEffect> presets = [
    AppImageEffect(id: originalId, name: 'Оригинал', matrix: AppImageEditColorMatrices.identity),
    AppImageEffect(
      id: 'luminar',
      name: 'Люмина',
      matrix: [1.08, 0.02, 0, 0, 8, 0, 1.04, 0, 0, 6, 0, 0, 0.96, 0, 0, 0, 0, 0, 1, 0],
    ),
    AppImageEffect(
      id: 'cool',
      name: 'Холод',
      matrix: [0.95, 0, 0, 0, 0, 0, 1.02, 0, 0, 0, 0, 0, 1.12, 0, 10, 0, 0, 0, 1, 0],
    ),
    AppImageEffect(
      id: 'maya',
      name: 'Майя',
      matrix: [0.93, 0.05, 0.02, 0, 18, 0.03, 0.92, 0.05, 0, 18, 0.02, 0.05, 0.88, 0, 18, 0, 0, 0, 1, 0],
    ),
    AppImageEffect(
      id: 'ray',
      name: 'Рей',
      matrix: [
        1.25,
        -0.05,
        -0.05,
        0,
        -10,
        -0.05,
        1.25,
        -0.05,
        0,
        -10,
        -0.05,
        -0.05,
        1.25,
        0,
        -10,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    AppImageEffect(
      id: 'paris',
      name: 'Пари',
      matrix: [1.05, 0.08, 0, 0, 12, 0.02, 1.0, 0, 0, 8, 0, 0.02, 0.92, 0, 0, 0, 0, 0, 1, 0],
    ),
    AppImageEffect(
      id: 'mono',
      name: 'Моно',
      matrix: [0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0, 0, 0, 1, 0],
    ),
    AppImageEffect(
      id: 'vivid',
      name: 'Яркий',
      matrix: [1.18, -0.05, -0.05, 0, 0, -0.05, 1.18, -0.05, 0, 0, -0.05, -0.05, 1.18, 0, 0, 0, 0, 0, 1, 0],
    ),
  ];

  static AppImageEffect byId(String id) {
    return presets.firstWhere((effect) => effect.id == id, orElse: () => presets.first);
  }
}

abstract final class AppImageEditColorMatrices {
  static const List<double> identity = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

  static List<double> compose(List<List<double>> matrices) {
    return matrices.fold<List<double>>(identity, multiply);
  }

  static List<double> multiply(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        if (col == 4) {
          out[row * 5 + 4] =
              a[row * 5 + 4] +
              b[4] * a[row * 5 + 0] +
              b[9] * a[row * 5 + 1] +
              b[14] * a[row * 5 + 2] +
              b[19] * a[row * 5 + 3];
          continue;
        }

        out[row * 5 + col] =
            a[row * 5 + 0] * b[col + 0] +
            a[row * 5 + 1] * b[col + 5] +
            a[row * 5 + 2] * b[col + 10] +
            a[row * 5 + 3] * b[col + 15];
      }
    }
    return out;
  }

  static List<double> brightness(double value) {
    final offset = value * 36;
    return [1, 0, 0, 0, offset, 0, 1, 0, 0, offset, 0, 0, 1, 0, offset, 0, 0, 0, 1, 0];
  }

  static List<double> contrast(double value) {
    final scale = 1 + value;
    final offset = (1 - scale) * 128;
    return [scale, 0, 0, 0, offset, 0, scale, 0, 0, offset, 0, 0, scale, 0, offset, 0, 0, 0, 1, 0];
  }

  static List<double> saturation(double value) {
    final s = 1 + value;
    const r = 0.2126;
    const g = 0.7152;
    const b = 0.0722;
    final ir = (1 - s) * r;
    final ig = (1 - s) * g;
    final ib = (1 - s) * b;
    return [ir + s, ig, ib, 0, 0, ir, ig + s, ib, 0, 0, ir, ig, ib + s, 0, 0, 0, 0, 0, 1, 0];
  }

  static List<double> warmth(double value) {
    final shift = value * 28;
    return [1, 0, 0, 0, shift, 0, 1, 0, 0, 0, 0, 0, 1, 0, -shift, 0, 0, 0, 1, 0];
  }

  static List<double> fade(double value) {
    final lift = value * 24;
    final scale = 1 - (value * 0.18);
    final offset = lift + (1 - scale) * 128;
    return [scale, 0, 0, 0, offset, 0, scale, 0, 0, offset, 0, 0, scale, 0, offset, 0, 0, 0, 1, 0];
  }
}
