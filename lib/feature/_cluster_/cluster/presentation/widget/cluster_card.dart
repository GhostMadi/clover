import 'package:cached_network_image/cached_network_image.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:clover/core/shared/jelly.dart';
import 'package:flutter/material.dart';

/// Ширина карточки 1x1 (px Figma).
const double kClusterCardWidthFigma = 164;

/// Высота полосы кластеров — теперь равна ширине (px Figma).
const double kClusterStripHeightFigma = 164;

double clusterCardWidth(BuildContext context) => context.widthByContext(kClusterCardWidthFigma);

double clusterStripHeight(BuildContext context) => context.heightByContext(kClusterStripHeightFigma);

/// Карточка кластера / коллекции в стиле 1х1 с инфо-чипсами поверх фото.
class ClusterCard extends StatefulWidget {
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

  // Квадратные пропорции 164х164
  static const double _figmaCardSize = 164;
  static const double _figmaCardRadius = 20; // Чуть увеличили скругление для сочности плитки
  static const double _figmaPadding = 10;
  static const double _figmaTitleFont = 13;
  static const double _figmaSubtitleFont = 10;
  static const double _figmaIconSize = 20;
  static const double _figmaMenuInset = 6;
  static const double _figmaMenuPadding = 6;
  static const double _figmaBorderSelected = 1.5;
  static const double _figmaBorderNormal = 0.85;

  @override
  State<ClusterCard> createState() => _ClusterCardState();
}

class _ClusterCardState extends State<ClusterCard> with SingleTickerProviderStateMixin {
  late final JellyPressController _jelly;

  @override
  void initState() {
    super.initState();
    _jelly = JellyPressController(
      vsync: this,
      onAnimationSwap: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _jelly.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    _jelly.trigger(haptic: false);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sel = widget.isSelected;
    final mid = widget.subtitle?.trim();
    final hasMid = mid != null && mid.isNotEmpty;
    final url = widget.coverUrl?.trim() ?? '';
    final hasThumb = url.isNotEmpty;
    final hasCount = widget.countLabel.trim().isNotEmpty;
    final menu = widget.menuItems;

    final cardRadius = context.widthByContext(ClusterCard._figmaCardRadius);
    final padding = context.widthByContext(ClusterCard._figmaPadding);
    final cardSize = context.widthByContext(ClusterCard._figmaCardSize);
    final titleFont = context.heightByContext(ClusterCard._figmaTitleFont);
    final subtitleFont = context.heightByContext(ClusterCard._figmaSubtitleFont);

    final cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: sel ? colors.primary : colors.border.withValues(alpha: 0.45),
          width: context.widthByContext(
            sel ? ClusterCard._figmaBorderSelected : ClusterCard._figmaBorderNormal,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius - 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: hasThumb
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(color: colors.surfaceSoft),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: colors.surfaceSoft,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: context.heightByContext(ClusterCard._figmaIconSize),
                          color: colors.iconMuted,
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: colors.surfaceSoft,
                      child: Center(
                        child: Icon(
                          Icons.folder_open_rounded,
                          size: context.heightByContext(ClusterCard._figmaIconSize),
                          color: colors.iconMuted,
                        ),
                      ),
                    ),
            ),

            // Затемнение снизу — текст поверх фото всегда читается.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.black.withValues(alpha: 0.0),
                      colors.black.withValues(alpha: 0.2),
                      colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(
                          titleFont,
                          color: colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),

                    if (hasMid || hasCount) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (hasMid)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  mid,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.base(
                                    subtitleFont,
                                    color: colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          if (hasCount) ...[
                            const SizedBox(width: 6),
                            _CountChip(label: widget.countLabel, selected: sel),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _jelly.scaleAnimation,
        builder: (context, child) {
          final s = _jelly.scaleAnimation.value;
          final vScale = 1.0 + (1.0 - s) * 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(s, vScale, 1.0)..setEntry(3, 2, 0.001),
            child: child,
          );
        },
        child: cardBody,
      ),
    );

    if (menu == null || menu.isEmpty) return card;

    final menuInset = context.widthByContext(ClusterCard._figmaMenuInset);
    final menuPadding = context.widthByContext(ClusterCard._figmaMenuPadding);
    final menuIconSize = context.heightByContext(ClusterCard._figmaIconSize);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          right: menuInset,
          top: menuInset,
          child: AppMiniMenu<String>(
            items: menu,
            onSelected: widget.onMenuSelected ?? (_) {},
            child: Container(
              padding: EdgeInsets.all(menuPadding),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.black.withValues(alpha: 0.45),
              ),
              child: Icon(AppIcons.moreVert.icon, size: menuIconSize, color: colors.white),
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
    final colors = context.colors;
    // Поверх фото: выбранный — primary; иначе светлая плашка с тёмным текстом (контраст в любой теме).
    final bg = selected ? colors.primary : colors.white;
    final fg = selected ? colors.white : const Color(0xFF1A1D1E);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthByContext(_figmaChipHPadding),
        vertical: context.heightByContext(_figmaChipVPadding),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.base(
          context.heightByContext(_figmaChipFont),
          color: fg,
          height: 1.05,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
