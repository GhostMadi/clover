import 'dart:math' as math;

import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

/// Разброс смайликов на фоне чата (стабильные позиции по seed).
class ChatEmojiWallpaperLayer extends StatelessWidget {
  const ChatEmojiWallpaperLayer({
    super.key,
    required this.emojis,
    required this.seed,
    this.opacity = 0.34,
  });

  final List<String> emojis;
  final String seed;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (emojis.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.12, 0.55),
        child: CustomPaint(
          painter: _EmojiScatterPainter(
            emojis: emojis,
            seed: seed,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _EmojiScatterPainter extends CustomPainter {
  _EmojiScatterPainter({required this.emojis, required this.seed});

  final List<String> emojis;
  final String seed;

  static const int _count = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (emojis.isEmpty || size.isEmpty) return;

    final rnd = math.Random(_hash(seed + emojis.join()));
    for (var i = 0; i < _count; i++) {
      final emoji = emojis[i % emojis.length];
      final fontSize = 18.0 + rnd.nextDouble() * 22.0;
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final rotation = (rnd.nextDouble() - 0.5) * 0.9;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final tp = TextPainter(
        text: TextSpan(text: emoji, style: AppTextStyle.emoji(fontSize)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EmojiScatterPainter oldDelegate) {
    return oldDelegate.seed != seed || !_listEq(oldDelegate.emojis, emojis);
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _hash(String s) {
    var h = 0;
    for (final u in s.codeUnits) {
      h = 0x1fffffff & (h + u);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= h >> 6;
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= h >> 11;
    return 0x1fffffff & (h + ((0x00003fff & h) << 15));
  }
}
