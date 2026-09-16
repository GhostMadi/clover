import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clover/core/theme/app_color_binding.dart';
import 'package:clover/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Рендер иконки маркера: круг-бейдж + emoji по центру круга.
///
/// Светлая тема → чёрный круг; тёмная → белый круг.
/// Серверный кластер (count &gt; 1) — тот же бейдж + маленький счётчик сбоку.
abstract final class AppMapMarkerIconFactory {
  static const _cacheVersion = 10;

  static const _size = 180.0;
  static const markerSize = _size;
  static const _radius = 78.0;
  static const _haloRadius = 84.0;
  static const _darkBorderWidth = 3.0;
  static const _borderWidth = 8.0;
  static const _countBadgeRadius = 26.0;

  /// Крупнее внутри круга (диаметр ~156).
  static const _emojiFontSize = 128.0;

  /// Emoji в шрифте сидит выше em-box — оптический сдвиг вниз к центру круга.
  static const _emojiOpticalOffsetY = 14.0;

  static const mapScale = 1.0;
  static const anchor = Offset(0.5, 0.5);

  static final Map<String, Future<Uint8List>> _cache = {};

  static void clearCache() => _cache.clear();

  static Future<Uint8List> bytesFor({
    required String emoji,
    Color borderColor = const Color(0xFF8BC34A),
    int count = 1,
  }) {
    final isDark = AppColorBinding.palette.brightness == Brightness.dark;
    final safeCount = count < 1 ? 1 : count;
    final key = '$_cacheVersion|${isDark ? 'd' : 'l'}|${emoji.trim()}|${borderColor.toARGB32()}|$safeCount';
    return _cache.putIfAbsent(
      key,
      () => _render(emoji: emoji, borderColor: borderColor, isDark: isDark, count: safeCount),
    );
  }

  static Future<Uint8List> _render({
    required String emoji,
    required Color borderColor,
    required bool isDark,
    required int count,
  }) async {
    final palette = AppColorBinding.palette;
    // Светлая карта → тёмный бейдж; тёмная → светлый.
    final fill = isDark ? palette.white : palette.black;
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
    canvas.drawCircle(center, _radius, Paint()..color = fill);
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

    if (count > 1) {
      _paintCountBadge(canvas, palette: palette, count: count);
    }

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  static void _paintCountBadge(Canvas canvas, {required AppPalette palette, required int count}) {
    // Top-right on the marker ring — count is a chip, emoji stays in the center.
    const badgeCenter = Offset(_size - 34, 34);
    canvas.drawCircle(
      badgeCenter,
      _countBadgeRadius + 2,
      Paint()..color = palette.shadowDark.withValues(alpha: 0.25),
    );
    canvas.drawCircle(badgeCenter, _countBadgeRadius, Paint()..color = palette.primary);
    canvas.drawCircle(
      badgeCenter,
      _countBadgeRadius,
      Paint()
        ..color = palette.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final label = count > 99 ? '99+' : '$count';
    final countPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: label.length > 2 ? 20 : 26,
          fontWeight: FontWeight.w700,
          color: palette.white,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    countPainter.paint(
      canvas,
      Offset(badgeCenter.dx - countPainter.width / 2, badgeCenter.dy - countPainter.height / 2),
    );
  }
}
