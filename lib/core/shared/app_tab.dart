import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Сегментированный переключатель вкладок с анимированной подложкой.
///
/// [scrollable]: вкладки берут ширину по тексту и скроллятся по горизонтали.
/// [service]: мягкий трек + цвет выбранного текста из сервисного акцента.
class AppTab extends StatelessWidget {
  const AppTab({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabChanged,
    this.scrollable = false,
    this.service,
  });

  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  /// Если `true` — ширина по содержимому + горизонтальный скролл.
  final bool scrollable;

  final AppServiceKind? service;

  static const double _outerPadding = 3;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();

    final index = currentIndex.clamp(0, tabs.length - 1);
    final colors = context.colors;
    final accent = service != null ? colors.serviceAccent(service!) : null;
    final trackColor = accent?.soft ?? colors.surfaceMuted;
    final selectedColor = accent?.icon ?? colors.textColor;

    if (scrollable) {
      return _ScrollableAppTab(
        tabs: tabs,
        currentIndex: index,
        onTabChanged: onTabChanged,
        trackColor: trackColor,
        selectedColor: selectedColor,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth - _outerPadding * 2;
        final tabWidth = totalWidth / tabs.length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(_outerPadding),
          decoration: ShapeDecoration(
            color: trackColor,
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
                child: const _TabIndicator(),
              ),
              Row(
                children: List.generate(tabs.length, (i) {
                  return Expanded(
                    child: _AppTabItem(
                      label: tabs[i],
                      isSelected: i == index,
                      expand: true,
                      selectedColor: selectedColor,
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

class _TabIndicator extends StatelessWidget {
  const _TabIndicator();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: ShapeDecoration(
        // Light: белая «таблетка». Dark: чуть светлее трека, не pure white.
        color: isDark ? colors.surfaceSoft : colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        shadows: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.45 : 0.1),
            blurRadius: isDark ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _ScrollableAppTab extends StatefulWidget {
  const _ScrollableAppTab({
    required this.tabs,
    required this.currentIndex,
    required this.onTabChanged,
    required this.trackColor,
    required this.selectedColor,
  });

  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final Color trackColor;
  final Color selectedColor;

  @override
  State<_ScrollableAppTab> createState() => _ScrollableAppTabState();
}

class _ScrollableAppTabState extends State<_ScrollableAppTab> {
  final ScrollController _controller = ScrollController();
  final GlobalKey _rowKey = GlobalKey();
  final List<GlobalKey> _keys = [];

  double _indicatorLeft = 0;
  double _indicatorWidth = 0;
  bool _hasMeasured = false;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndScroll());
  }

  @override
  void didUpdateWidget(covariant _ScrollableAppTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    final tabsChanged = oldWidget.tabs.length != widget.tabs.length || !_sameTabs(oldWidget.tabs, widget.tabs);
    if (oldWidget.currentIndex != widget.currentIndex || tabsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndScroll());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _sameTabs(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _syncKeys() {
    while (_keys.length < widget.tabs.length) {
      _keys.add(GlobalKey());
    }
    if (_keys.length > widget.tabs.length) {
      _keys.removeRange(widget.tabs.length, _keys.length);
    }
  }

  void _measureAndScroll() {
    if (!mounted) return;

    final rowCtx = _rowKey.currentContext;
    final index = widget.currentIndex.clamp(0, _keys.length - 1);
    final tabCtx = _keys[index].currentContext;
    if (rowCtx == null || tabCtx == null) return;

    final rowBox = rowCtx.findRenderObject() as RenderBox?;
    final tabBox = tabCtx.findRenderObject() as RenderBox?;
    if (rowBox == null || tabBox == null || !rowBox.hasSize || !tabBox.hasSize) return;

    final tabOffset = tabBox.localToGlobal(Offset.zero, ancestor: rowBox);
    final nextLeft = tabOffset.dx;
    final nextWidth = tabBox.size.width;

    if (!_hasMeasured || nextLeft != _indicatorLeft || nextWidth != _indicatorWidth) {
      setState(() {
        _indicatorLeft = nextLeft;
        _indicatorWidth = nextWidth;
        _hasMeasured = true;
      });
    }

    Scrollable.ensureVisible(
      tabCtx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTab._outerPadding),
      decoration: ShapeDecoration(
        color: widget.trackColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Stack(
          children: [
            if (_hasMeasured && _indicatorWidth > 0)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _indicatorLeft,
                width: _indicatorWidth,
                top: 0,
                bottom: 0,
                child: const _TabIndicator(),
              ),
            Row(
              key: _rowKey,
              children: List.generate(widget.tabs.length, (i) {
                return KeyedSubtree(
                  key: _keys[i],
                  child: _AppTabItem(
                    label: widget.tabs[i],
                    isSelected: i == widget.currentIndex,
                    expand: false,
                    selectedColor: widget.selectedColor,
                    onTap: () {
                      if (i != widget.currentIndex) {
                        HapticFeedback.selectionClick();
                        widget.onTabChanged(i);
                      }
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTabItem extends StatefulWidget {
  const _AppTabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    this.expand = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final bool expand;

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
    final colors = context.colors;

    return AnimatedBuilder(
      animation: _jellyController.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _jellyController.scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: widget.expand ? 0 : 14,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: AppTextStyle.base(
              14,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected ? widget.selectedColor : colors.subTextColor,
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: widget.expand ? TextOverflow.ellipsis : TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }
}
