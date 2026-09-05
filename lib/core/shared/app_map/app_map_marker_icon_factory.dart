import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clover/core/theme/app_color_binding.dart';
import 'package:flutter/material.dart';

/// Рендер иконки маркера: круг-бейдж + emoji по центру круга.
abstract final class AppMapMarkerIconFactory {
  static const _cacheVersion = 10;

  static const _size = 180.0;
  static const markerSize = _size;
  static const _radius = 78.0;
  static const _haloRadius = 84.0;
  static const _darkBorderWidth = 3.0;
  static const _borderWidth = 8.0;

  /// Влезает внутрь круга (диаметр ~156); раньше 150 вылезало и визуально «ездило».
  static const _emojiFontSize = 108.0;

  /// Emoji в шрифте сидит выше em-box — оптический сдвиг вниз к центру круга.
  static const _emojiOpticalOffsetY = 12.0;

  static const mapScale = 1.0;
  static const anchor = Offset(0.5, 0.5);

  static final Map<String, Future<Uint8List>> _cache = {};

  static Future<Uint8List> bytesFor({required String emoji, Color borderColor = const Color(0xFF8BC34A)}) {
    final key = '$_cacheVersion|${emoji.trim()}|${borderColor.toARGB32()}';
    return _cache.putIfAbsent(key, () => _render(emoji: emoji, borderColor: borderColor));
  }

  static Future<Uint8List> _render({required String emoji, required Color borderColor}) async {
    final palette = AppColorBinding.palette;
    const size = _size;
    const center = Offset(size / 2, size / 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      center.translate(0, 4),
      _radius + 2,
      Paint()..color = palette.shadowDark.withValues(alpha: 0.28),
    );
    canvas.drawCircle(center, _haloRadius, Paint()..color = palette.shadowDark.withValues(alpha: 0.2));
    canvas.drawCircle(center, _radius, Paint()..color = palette.white);
    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..color = palette.shadowDark.withValues(alpha: 0.5)
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

    final displayEmoji = emoji.trim().isEmpty ? '📍' : emoji.trim();
    final painter = TextPainter(
      text: TextSpan(
        text: displayEmoji,
        style: const TextStyle(fontSize: _emojiFontSize, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Геометрический центр + сдвиг вниз (метрики emoji), clip — не вылезает за круг.
    final emojiOrigin = Offset(
      center.dx - painter.width / 2,
      center.dy - painter.height / 2 + _emojiOpticalOffsetY,
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: _radius - _borderWidth / 2)));
    painter.paint(canvas, emojiOrigin);
    canvas.restore();

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }
}
