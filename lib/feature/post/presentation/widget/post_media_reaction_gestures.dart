import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/gestures/sequential_tap_detector.dart';
import 'package:flutter/material.dart';

/// Двойной тап — лайк, тройной — дизлайк (Instagram-style) с анимацией иконки.
class PostMediaReactionGestures extends StatefulWidget {
  const PostMediaReactionGestures({
    super.key,
    required this.child,
    required this.isLiked,
    required this.isDisliked,
    required this.onLike,
    required this.onDislike,
  });

  final Widget child;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  @override
  State<PostMediaReactionGestures> createState() => _PostMediaReactionGesturesState();
}

class _PostMediaReactionGesturesState extends State<PostMediaReactionGestures> with SingleTickerProviderStateMixin {
  late final SequentialTapDetector _tapDetector;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  IconData? _overlayIcon;
  Color _overlayIconColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tapDetector = SequentialTapDetector();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_animationController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 0.9), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 0.0), weight: 20),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _tapDetector.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapDetector.registerTap((tapCount) {
      if (tapCount == 2) {
        _triggerLike();
      } else if (tapCount >= 3) {
        _triggerDislike();
      }
    });
  }

  void _triggerLike() {
    if (!widget.isLiked) {
      widget.onLike();
    }
    setState(() {
      _overlayIcon = AppIcons.likeFilled.icon;
      _overlayIconColor = Colors.red.withValues(alpha: 0.95);
    });
    _animationController.forward(from: 0);
  }

  void _triggerDislike() {
    if (!widget.isDisliked) {
      widget.onDislike();
    }
    setState(() {
      _overlayIcon = AppIcons.dislikeFilled.icon;
      _overlayIconColor = AppColors.textColor.withValues(alpha: 0.85);
    });
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_overlayIcon != null)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(_overlayIcon, size: 110, color: _overlayIconColor),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
