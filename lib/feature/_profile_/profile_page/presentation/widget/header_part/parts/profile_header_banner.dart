import 'package:clover/core/extension/context.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:clover/core/storage/app_progressive_network_image.dart';
import 'package:flutter/material.dart';

/// Верхний баннер профиля (квадратная обложка с jelly-анимацией по тапу).
class ProfileHeaderBanner extends StatefulWidget {
  const ProfileHeaderBanner({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<ProfileHeaderBanner> createState() => _ProfileHeaderBannerState();
}

class _ProfileHeaderBannerState extends State<ProfileHeaderBanner> with SingleTickerProviderStateMixin {
  static const double _figmaPadding = 12;
  static const double _figmaRadius = 24;
  static const double _figmaHeight = 150;

  late final JellyPressController _jelly;
  late final ValueNotifier<int> _animationGeneration;

  @override
  void initState() {
    super.initState();
    _animationGeneration = ValueNotifier(0);
    _jelly = JellyPressController(vsync: this, onAnimationSwap: () => _animationGeneration.value++);
  }

  @override
  void dispose() {
    _jelly.dispose();
    _animationGeneration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = context.widthByContext(_figmaPadding);
    final radius = context.widthByContext(_figmaRadius);
    final height = context.heightByContext(_figmaHeight);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _jelly.trigger,
        child: ValueListenableBuilder<int>(
          valueListenable: _animationGeneration,
          builder: (context, _, __) {
            return AnimatedBuilder(
              animation: _jelly.scaleAnimation,
              builder: (context, child) {
                final s = _jelly.scaleAnimation.value;
                final vScale = 1.0 + (1.0 - s) * 0.5;
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(s, vScale, 1.0)..setEntry(3, 2, 0.001),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: SizedBox(
                  width: double.infinity,
                  height: height,
                  child: AppProgressiveNetworkImage(
                    imageUrl: widget.imageUrl,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
