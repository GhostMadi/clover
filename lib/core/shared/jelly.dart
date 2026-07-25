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

/// Jelly squash при смене [trigger] (первый кадр не анимирует).
class JellyBounce extends StatefulWidget {
  const JellyBounce({
    super.key,
    required this.trigger,
    required this.child,
    this.haptic = false,
    this.alignment = Alignment.center,
  });

  final Object trigger;
  final Widget child;
  final bool haptic;
  final Alignment alignment;

  @override
  State<JellyBounce> createState() => _JellyBounceState();
}

class _JellyBounceState extends State<JellyBounce> with SingleTickerProviderStateMixin {
  late final JellyPressController _jelly;
  late final ValueNotifier<int> _generation;

  @override
  void initState() {
    super.initState();
    _generation = ValueNotifier(0);
    _jelly = JellyPressController(vsync: this, onAnimationSwap: () => _generation.value++);
  }

  @override
  void didUpdateWidget(JellyBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _jelly.trigger(haptic: widget.haptic);
    }
  }

  @override
  void dispose() {
    _jelly.dispose();
    _generation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _generation,
      builder: (context, _, __) {
        return AnimatedBuilder(
          animation: _jelly.scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _jelly.scaleAnimation.value,
              alignment: widget.alignment,
              child: child,
            );
          },
          child: widget.child,
        );
      },
    );
  }
}
