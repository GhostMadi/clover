import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Сегментированный переключатель вкладок с анимированной подложкой.
class AppTab extends StatelessWidget {
  const AppTab({super.key, required this.tabs, required this.currentIndex, required this.onTabChanged});

  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  static const double _outerPadding = 3;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();

    final index = currentIndex.clamp(0, tabs.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth - _outerPadding * 2;
        final tabWidth = totalWidth / tabs.length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_outerPadding),
          decoration: ShapeDecoration(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: index * tabWidth,
                width: tabWidth,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    shadows: [
                      BoxShadow(
                        color: AppColors.shadowDark.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(tabs.length, (i) {
                  return Expanded(
                    child: _AppTabItem(
                      label: tabs[i],
                      isSelected: i == index,
                      onTap: () {
                        if (i != index) {
                          HapticFeedback.selectionClick();
                          onTabChanged(i);
                        }
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppTabItem extends StatefulWidget {
  const _AppTabItem({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_AppTabItem> createState() => _AppTabItemState();
}

class _AppTabItemState extends State<_AppTabItem> with SingleTickerProviderStateMixin {
  late final JellyPressController _jellyController;

  @override
  void initState() {
    super.initState();
    _jellyController = JellyPressController(
      vsync: this,
      onAnimationSwap: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _jellyController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _jellyController.trigger(haptic: false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: AppTextStyle.base(
              14,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected ? AppColors.textColor : AppColors.subTextColor,
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
