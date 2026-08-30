import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clover/core/resources/colors.dart';
import 'package:flutter/material.dart';

/// Рендер иконки маркера: круг-бейдж + emoji поверх (stack), emoji чуть выходит за круг.
abstract final class AppMapMarkerIconFactory {
  static const _cacheVersion = 6;

  static const _size = 180.0;
  static const markerSize = _size;
  static const _radius = 78.0;
  static const _haloRadius = 84.0;
  static const _darkBorderWidth = 3.0;
  static const _borderWidth = 8.0;
  static const _emojiFontSize = 150.0;

  static const mapScale = 1.0;

  static final Map<String, Future<Uint8List>> _cache = {};

  static Future<Uint8List> bytesFor({required String emoji, Color borderColor = const Color(0xFF8BC34A)}) {
    final key = '$_cacheVersion|${emoji.trim()}|${borderColor.toARGB32()}';
    return _cache.putIfAbsent(key, () => _render(emoji: emoji, borderColor: borderColor));
  }

  static Future<Uint8List> _render({required String emoji, required Color borderColor}) async {
    const size = _size;
    const center = Offset(size / 2, size / 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Бейдж (круг снизу)
    final dropShadow = Paint()..color = AppColors.shadowDark.withValues(alpha: 0.28);
    canvas.drawCircle(center.translate(0, 4), _radius + 2, dropShadow);

    final halo = Paint()..color = AppColors.shadowDark.withValues(alpha: 0.2);
    canvas.drawCircle(center, _haloRadius, halo);

    canvas.drawCircle(center, _radius, Paint()..color = AppColors.white);

    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..color = AppColors.shadowDark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _darkBorderWidth,
    );

    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );

    // 2. Emoji сверху — без clip, слегка крупнее круга
    final displayEmoji = emoji.trim().isEmpty ? '📍' : emoji.trim();
    final painter = TextPainter(
      text: TextSpan(
        text: displayEmoji,
        style: const TextStyle(fontSize: _emojiFontSize, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final emojiCenter = center - Offset(painter.width / 2, painter.height / 2 - 2);
    painter.paint(canvas, emojiCenter);

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
