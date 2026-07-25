import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clover/core/shared/app_map/app_map_marker_icon_factory.dart';
import 'package:flutter/material.dart';

/// Иконка стопки / кластера: до 3 полноразмерных маркеров веером.
abstract final class AppMapClusterIconFactory {
  static const _cacheVersion = 3;

  static const canvasWidth = 300.0;
  static const canvasHeight = 230.0;
  static const anchor = Offset(0.5, 0.58);

  static final Map<String, Future<Uint8List>> _cache = {};

  static Future<Uint8List> bytesFor({required List<String> emojis, required int count}) {
    final visible = _visibleEmojis(emojis, count);
    final key = '$_cacheVersion|$count|${visible.join('|')}';
    return _cache.putIfAbsent(key, () => _render(visibleEmojis: visible));
  }

  static List<String> _visibleEmojis(List<String> emojis, int count) {
    final normalized = emojis.isEmpty
        ? List<String>.filled(math.min(count, 3), '📍')
        : [
            for (final emoji in emojis)
              emoji.trim().isEmpty ? '📍' : emoji.trim(),
          ];

    final limit = count <= 1 ? 1 : count == 2 ? 2 : 3;
    return normalized.take(limit).toList(growable: false);
  }

  static Future<Uint8List> _render({required List<String> visibleEmojis}) async {
    final images = await Future.wait(
      visibleEmojis.map((emoji) async {
        final bytes = await AppMapMarkerIconFactory.bytesFor(emoji: emoji);
        final codec = await ui.instantiateImageCodec(bytes);
        return (await codec.getNextFrame()).image;
      }),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final slots = _layoutSlots(visibleEmojis.length);

    for (var i = 0; i < images.length; i++) {
      final slot = slots[i];
      _drawMarker(canvas, images[i], slot.center, slot.rotationRad);
    }

    for (final image in images) {
      image.dispose();
    }

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    picture.dispose();

    final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();
    return data!.buffer.asUint8List();
  }

  static List<_FanSlot> _layoutSlots(int count) {
    const cx = canvasWidth / 2;
    const cy = canvasHeight / 2;

    return switch (count) {
      1 => [_FanSlot(Offset(cx, cy), 0)],
      2 => [
          _FanSlot(Offset(cx - 58, cy + 10), _deg(-16)),
          _FanSlot(Offset(cx + 58, cy + 10), _deg(16)),
        ],
      _ => [
          _FanSlot(Offset(cx, cy - 12), 0),
          _FanSlot(Offset(cx - 72, cy + 18), _deg(-22)),
          _FanSlot(Offset(cx + 72, cy + 18), _deg(22)),
        ],
    };
  }

  static double _deg(double degrees) => degrees * math.pi / 180;

  static void _drawMarker(Canvas canvas, ui.Image image, Offset center, double rotationRad) {
    final half = AppMapMarkerIconFactory.markerSize / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationRad);
    canvas.drawImage(image, Offset(-half, -half), Paint());
    canvas.restore();
  }
}

class _FanSlot {
  const _FanSlot(this.center, this.rotationRad);

  final Offset center;
  final double rotationRad;
}
