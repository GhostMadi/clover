import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Оболочка поля — как [AppField], но только для тапа (без клавиатуры).
class AppPickerFieldShell extends StatelessWidget {
  const AppPickerFieldShell({
    super.key,
    this.label,
    required this.hint,
    required this.displayText,
    required this.onTap,
    this.prefixIcon,
    this.enabled = true,
  });

  final String? label;
  final String hint;
  final String? displayText;
  final VoidCallback? onTap;
  final IconData? prefixIcon;
  final bool enabled;

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = displayText != null && displayText!.trim().isNotEmpty;
    final canTap = enabled && onTap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label!,
              style: AppTextStyle.base(13, fontWeight: FontWeight.w600, color: colors.fieldLabel),
            ),
          ),
        ],
        Material(
          color: enabled ? colors.fieldBackground : colors.fieldBackgroundDisabled,
          borderRadius: BorderRadius.circular(_radius),
          child: InkWell(
            onTap: canTap ? onTap : null,
            borderRadius: BorderRadius.circular(_radius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: colors.fieldBorder),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowDark.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (prefixIcon != null) ...[
                    Icon(prefixIcon, size: 22, color: colors.fieldIcon),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      hasValue ? displayText!.trim() : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        16,
                        fontWeight: FontWeight.w500,
                        color: hasValue
                            ? (enabled ? colors.fieldText : colors.fieldTextDisabled)
                            : colors.fieldHint,
                      ),
                    ),
                  ),
                  Icon(
                    AppIcons.arrowDown.icon,
                    color: colors.subTextColor.withValues(alpha: 0.55),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Кастомная колонка-барабан для пикеров.
class AppPickerWheel extends StatefulWidget {
  const AppPickerWheel({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    this.width,
    this.service,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final double? width;
  final AppServiceKind? service;

  static const double itemExtent = 46;

  @override
  State<AppPickerWheel> createState() => _AppPickerWheelState();
}

class _AppPickerWheelState extends State<AppPickerWheel> {
  late FixedExtentScrollController _controller;
  int _lastHapticIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.selectedIndex.clamp(0, _maxIndex));
    _lastHapticIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant AppPickerWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex && _controller.hasClients) {
      final target = widget.selectedIndex.clamp(0, _maxIndex);
      if (_controller.selectedItem != target) {
        _controller.animateToItem(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  int get _maxIndex => widget.items.isEmpty ? 0 : widget.items.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelected(int index) {
    if (index == _lastHapticIndex) return;
    _lastHapticIndex = index;
    HapticFeedback.selectionClick();
    widget.onSelectedIndexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final serviceAccent = widget.service != null ? colors.serviceAccent(widget.service!) : null;
    final highlight = serviceAccent?.cta ?? colors.primary;

    return SizedBox(
      width: widget.width,
      height: AppPickerWheel.itemExtent * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8,
            right: 8,
            height: AppPickerWheel.itemExtent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: highlight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: highlight.withValues(alpha: 0.22)),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: AppPickerWheel.itemExtent,
            diameterRatio: 1.35,
            perspective: 0.003,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: _onSelected,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.items.length,
              builder: (context, index) {
                final selected = index == widget.selectedIndex;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: AppTextStyle.base(
                      selected ? 18 : 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colors.textColor : colors.subTextColor.withValues(alpha: 0.75),
                    ),
                    child: Text(widget.items[index], textAlign: TextAlign.center),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
