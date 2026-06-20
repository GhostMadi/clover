import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_field/english_address_input_formatter.dart';
import 'package:flutter/material.dart';

/// Компактная плавающая панель адреса поверх карты (вместо AppBar).
class LocationCreateAddressBar extends StatefulWidget {
  const LocationCreateAddressBar({
    super.key,
    required this.cyrillicController,
    required this.secondaryController,
  });

  final TextEditingController cyrillicController;
  final TextEditingController secondaryController;

  @override
  State<LocationCreateAddressBar> createState() => _LocationCreateAddressBarState();
}

class _LocationCreateAddressBarState extends State<LocationCreateAddressBar> {
  bool _expanded = false;

  static const _horizontalMargin = 16.0;
  static const _topMargin = 8.0;

  @override
  void initState() {
    super.initState();
    widget.cyrillicController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.cyrillicController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + _topMargin;
    final cyrillic = widget.cyrillicController.text.trim();

    return Positioned(
      top: top,
      left: _horizontalMargin,
      right: _horizontalMargin,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded ? _buildExpanded() : _buildCollapsed(cyrillic),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsed(String cyrillic) {
    final hasAddress = cyrillic.isNotEmpty;

    return InkWell(
      onTap: _toggleExpanded,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 22,
              color: hasAddress ? AppColors.primary : AppColors.iconMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasAddress ? cyrillic : 'Адрес · нажмите, чтобы ввести',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.base(
                  14,
                  color: hasAddress ? AppColors.textColor : AppColors.subTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: AppColors.iconMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Адрес',
                      style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_up_rounded, size: 22, color: AppColors.iconMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          AppField(
            controller: widget.cyrillicController,
            hintText: 'Abay ave, 150, Almaty',
            prefixIcon: Icons.location_on_outlined,
            textInputAction: TextInputAction.next,
            inputFormatters: const [EnglishAddressInputFormatter()],
          ),
          const SizedBox(height: 8),
          AppField(
            controller: widget.secondaryController,
            hintText: 'ул. Абая, 150, Алматы (необязательно)',
            prefixIcon: Icons.translate_rounded,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
