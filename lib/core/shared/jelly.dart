import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Один цикл squash по нажатию. Кадры идут через [scaleAnimation] + AnimatedBuilder без setState на каждый tick.
final class JellyPressController {
  JellyPressController({required TickerProvider vsync, required VoidCallback onAnimationSwap})
    : _onAnimationSwap = onAnimationSwap,
      _controller = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 600)) {
    _scaleAnimation = _tween(1, 1, Curves.linear);
  }

  final AnimationController _controller;
  final VoidCallback _onAnimationSwap;
  late Animation<double> _scaleAnimation;

  Animation<double> get scaleAnimation => _scaleAnimation;

  Animation<double> _tween(double begin, double end, Curve curve) {
    return Tween<double>(begin: begin, end: end).animate(CurvedAnimation(parent: _controller, curve: curve));
  }

  void trigger({bool haptic = true}) {
    if (haptic) HapticFeedback.heavyImpact();
    _scaleAnimation = _tween(0.85, 1.0, Curves.elasticOut);
    _controller.forward(from: 0);
    _onAnimationSwap();
  }

  void dispose() {
    _controller.dispose();
  }
}
