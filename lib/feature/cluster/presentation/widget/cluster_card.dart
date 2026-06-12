import 'package:cached_network_image/cached_network_image.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:flutter/material.dart';

/// Ширина карточки в горизонтальном списке (px Figma).
const double kClusterCardWidthFigma = 212;

/// Высота полосы кластеров — карточка + вертикальные отступы списка (px Figma).
const double kClusterStripHeightFigma = 88;

double clusterCardWidth(BuildContext context) => context.widthByContext(kClusterCardWidthFigma);

double clusterStripHeight(BuildContext context) => context.heightByContext(kClusterStripHeightFigma);

/// Карточка кластера / коллекции.
class ClusterCard extends StatelessWidget {
  const ClusterCard({
    super.key,
    required this.title,
    this.subtitle,
    this.coverUrl,
    required this.countLabel,
    this.isSelected = false,
    this.onTap,
    this.menuItems,
    this.onMenuSelected,
  });

  final String title;
  final String? subtitle;
  final String? coverUrl;
  final String countLabel;
  final bool isSelected;
  final VoidCallback? onTap;
  final List<AppMiniMenuItem<String>>? menuItems;
  final ValueChanged<String>? onMenuSelected;

  static const double _figmaCardWidth = 212;
  static const double _figmaRowHeight = 64;
  static const double _figmaThumb = 52;
  static const double _figmaCardRadius = 18;
  static const double _figmaThumbRadius = 11;
  static const double _figmaPadding = 10;
  static const double _figmaGapThumb = 10;
  static const double _figmaTitleFont = 14;
  static const double _figmaSubtitleFont = 11;
  static const double _figmaGapTitleCount = 6;
  static const double _figmaGapTitleSubtitle = 4;
  static const double _figmaIconSize = 20;
  static const double _figmaMenuInset = 2;
  static const double _figmaMenuPadding = 6;
  static const double _figmaBorderSelected = 1.15;
  static const double _figmaBorderNormal = 0.85;

  @override
  Widget build(BuildContext context) {
    final sel = isSelected;
    final mid = subtitle?.trim();
    final hasMid = mid != null && mid.isNotEmpty;
    final url = coverUrl?.trim() ?? '';
    final hasThumb = url.isNotEmpty;
    final hasCount = countLabel.trim().isNotEmpty;
    final menu = menuItems;

    final cardRadius = context.widthByContext(_figmaCardRadius);
    final thumbRadius = context.widthByContext(_figmaThumbRadius);
    final padding = context.widthByContext(_figmaPadding);
    final rowHeight = context.heightByContext(_figmaRowHeight);
    final thumb = context.heightByContext(_figmaThumb);
    final titleFont = context.heightByContext(_figmaTitleFont);
    final subtitleFont = context.heightByContext(_figmaSubtitleFont);

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: context.widthByContext(_figmaCardWidth),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            color: sel ? AppColors.successSoft.withValues(alpha: 0.5) : AppColors.white,
            border: Border.all(
              color: sel
                  ? AppColors.primary.withValues(alpha: 0.38)
                  : AppColors.border.withValues(alpha: 0.55),
              width: context.widthByContext(sel ? _figmaBorderSelected : _figmaBorderNormal),
            ),
          ),
          child: SizedBox(
            height: rowHeight,
            child: Row(
              children: [
                if (hasThumb) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(thumbRadius),
                    child: SizedBox(
                      width: thumb,
                      height: thumb,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ColoredBox(color: AppColors.surfaceSoft),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: AppColors.surfaceSoft,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: context.heightByContext(_figmaIconSize),
                            color: AppColors.iconMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.widthByContext(_figmaGapThumb)),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.base(
                                titleFont,
                                color: sel ? AppColors.primary : AppColors.textColor,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (hasCount) ...[
                            SizedBox(width: context.widthByContext(_figmaGapTitleCount)),
                            _CountChip(label: countLabel, selected: sel),
                          ],
                        ],
                      ),
                      if (hasMid) ...[
                        SizedBox(height: context.heightByContext(_figmaGapTitleSubtitle)),
                        Text(
                          mid,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(
                            subtitleFont,
                            color: AppColors.subTextColor.withValues(alpha: 0.88),
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (menu == null || menu.isEmpty) return card;

    final menuInset = context.widthByContext(_figmaMenuInset);
    final menuPadding = context.widthByContext(_figmaMenuPadding);
    final menuIconSize = context.heightByContext(_figmaIconSize);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          right: menuInset,
          top: menuInset,
          child: AppMiniMenu<String>(
            items: menu,
            onSelected: onMenuSelected ?? (_) {},
            child: Padding(
              padding: EdgeInsets.all(menuPadding),
              child: Icon(Icons.more_vert_rounded, size: menuIconSize, color: AppColors.iconMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  static const double _figmaChipHPadding = 7;
  static const double _figmaChipVPadding = 3;
  static const double _figmaChipFont = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthByContext(_figmaChipHPadding),
        vertical: context.heightByContext(_figmaChipVPadding),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.primary.withValues(alpha: selected ? 0.16 : 0.1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.base(
          context.heightByContext(_figmaChipFont),
          color: AppColors.primary.withValues(alpha: selected ? 0.95 : 0.75),
          height: 1.05,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
