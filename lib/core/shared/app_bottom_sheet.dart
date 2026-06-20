import 'dart:math';

import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Скругление карточки шторки (сверху и снизу одинаково): снизу видно из-за [sheetOuterPadding].
const BorderRadius _kAppBottomSheetRadius = BorderRadius.all(Radius.circular(20));

/// Общая нижняя шторка: белый фон, «желейное» появление, тап по фону закрывает.
///
/// Возвращает результат [Navigator.pop], если его передали (например выбор в списке).
abstract final class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    bool upperCaseTitle = true,
    bool showCloseButton = false,

    /// Фиксированная высота области контента. Если `null` — высота по содержимому
    /// (с ограничением по экрану); для списков задайте [ListView.shrinkWrap] = true.
    double? contentHeight,

    /// Вертикальный зазор между [content] и нижним краем карточки (до [actions]).
    /// Для экранов с основной кнопкой внутри [content] можно поставить `0`, чтобы прижать её вниз.
    double contentBottomSpacing = 18,

    /// Внутренние отступы вокруг [content] (по умолчанию 16 слева/справа).
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 16),

    /// Поля между краем экрана и карточкой; к нижнему значению прибавляется [SafeArea.bottom] внутри [show].
    EdgeInsetsGeometry sheetOuterPadding = const EdgeInsets.fromLTRB(16, 0, 16, 12),

    /// Явная ширина карточки; если `null` — как раньше: `min(screenW - горизонтальные sheetOuter, 500)`.
    double? sheetWidth,

    /// Фон как у ленты/деталки постов ([AppColors.pageBackground]), без блюра — для длинных списков постов в шторке.
    bool postFeedSurface = false,

    /// Растянуть [content] на всю доступную высоту (только для длинных списков, напр. теги маркера).
    bool expandBody = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: barrierDismissible,
      enableDrag: barrierDismissible,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(modalContext).bottom),
          child: LayoutBuilder(
            builder: (layoutContext, constraints) {
              final screenW = MediaQuery.sizeOf(layoutContext).width;
              final dir = Directionality.of(layoutContext);
              final resolvedOuter = sheetOuterPadding.resolve(dir);
              final safeBottom = MediaQuery.paddingOf(layoutContext).bottom;
              final outer = EdgeInsets.fromLTRB(
                resolvedOuter.left,
                resolvedOuter.top,
                resolvedOuter.right,
                resolvedOuter.bottom + safeBottom,
              );
              final horizontalGap = outer.left + outer.right;
              final sheetW = sheetWidth ?? min(screenW - horizontalGap, 500.0);

              final maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(layoutContext).height - MediaQuery.viewInsetsOf(layoutContext).bottom;

              final availableH = max(0.0, maxH - outer.top - outer.bottom);

              /// Резерв под ручку, опционально заголовок/кнопки и отступы — без области [content].
              /// Без заголовка 200 давало искусственный «потолок» ~200 и сильно жалело списки.
              var chromeReserve = 12.0 + 4.0 + 16.0 + contentBottomSpacing;
              if (title != null) {
                chromeReserve += 44.0 + 1.0 + 8.0;
              }
              if (actions != null && actions.isNotEmpty) {
                chromeReserve += 20.0 + 52.0;
              }

              final resolvedContentPadding = contentPadding.resolve(dir);
              chromeReserve += resolvedContentPadding.vertical;

              Widget body = content;
              final scrollContent = !expandBody && contentHeight == null;
              if (contentHeight != null) {
                final cap = max(0.0, availableH - chromeReserve);
                body = SizedBox(height: min(contentHeight, cap), child: content);
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: barrierDismissible ? () => Navigator.pop(modalContext) : null,
                    ),
                  ),
                  _JellySheetWrapper(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: outer,
                        child: GestureDetector(
                          onTap: () {},
                          child: ClipRRect(
                            borderRadius: _kAppBottomSheetRadius,
                            child: RepaintBoundary(
                              child: _DecoratedSheetBody(
                                postFeedSurface: postFeedSurface,
                                sheetWidth: sheetW,
                                maxSheetHeight: availableH,
                                expandBody: expandBody,
                                title: title,
                                upperCaseTitle: upperCaseTitle,
                                showCloseButton: showCloseButton,
                                onClose: () => Navigator.pop(modalContext),
                                contentPadding: contentPadding,
                                contentBottomSpacing: contentBottomSpacing,
                                actions: actions,
                                scrollContent: scrollContent,
                                body: body,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _DecoratedSheetBody extends StatelessWidget {
  const _DecoratedSheetBody({
    required this.postFeedSurface,
    required this.sheetWidth,
    required this.maxSheetHeight,
    required this.expandBody,
    required this.scrollContent,
    required this.title,
    required this.upperCaseTitle,
    required this.showCloseButton,
    required this.onClose,
    required this.contentPadding,
    required this.contentBottomSpacing,
    required this.actions,
    required this.body,
  });

  final bool postFeedSurface;
  final double sheetWidth;
  final double maxSheetHeight;
  final bool expandBody;
  final bool scrollContent;
  final String? title;
  final bool upperCaseTitle;
  final bool showCloseButton;
  final VoidCallback onClose;
  final EdgeInsetsGeometry contentPadding;
  final double contentBottomSpacing;
  final List<Widget>? actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final actionRow = actions;
    final decoration = postFeedSurface
        ? BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: _kAppBottomSheetRadius,
            border: Border.all(color: AppColors.borderSoft, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          )
        : BoxDecoration(
            color: AppColors.white,
            borderRadius: _kAppBottomSheetRadius,
            border: Border.all(color: AppColors.borderSoft, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          );

    final content = DefaultTextStyle(
      style: AppTextStyle.base(15, color: AppColors.textColor, height: 1.5),
      child: body,
    );

    final paddedContent = Padding(padding: contentPadding, child: content);

    final bodySection = switch ((expandBody, scrollContent)) {
      (true, _) => Expanded(child: paddedContent),
      (false, true) => Flexible(
        fit: FlexFit.loose,
        child: SingleChildScrollView(physics: const ClampingScrollPhysics(), child: paddedContent),
      ),
      (false, false) => Flexible(
        fit: FlexFit.loose,
        child: paddedContent,
      ),
    };

    Widget column = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Container(
        width: sheetWidth,
        decoration: decoration,
        child: Column(
          mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.subTextColor.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              _BottomSheetHeader(
                title: title!,
                upperCaseTitle: upperCaseTitle,
                showCloseButton: showCloseButton,
                onClose: onClose,
              ),
              Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.65)),
              const SizedBox(height: 8),
            ],
            bodySection,
            SizedBox(height: contentBottomSpacing),
            if (actionRow != null && actionRow.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    for (var i = 0; i < actionRow.length; i++) ...[
                      Expanded(child: actionRow[i]),
                      if (i < actionRow.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return column;
  }
}

/// Заголовок слева (нейтральный текст), тонкий акцент бренда, справа — компактное закрытие.
class _BottomSheetHeader extends StatelessWidget {
  const _BottomSheetHeader({
    required this.title,
    required this.upperCaseTitle,
    required this.showCloseButton,
    required this.onClose,
  });

  final String title;
  final bool upperCaseTitle;
  final bool showCloseButton;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final label = upperCaseTitle ? title.toUpperCase() : title;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.base(
                  17,
                  color: AppColors.textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: upperCaseTitle ? 0.35 : 0,
                ),
              ),
            ),
            if (showCloseButton)
              IconButton(
                onPressed: onClose,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                style: IconButton.styleFrom(foregroundColor: AppColors.subTextColor),
                icon: const Icon(Icons.close_rounded, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

class _JellySheetWrapper extends StatefulWidget {
  const _JellySheetWrapper({required this.child});

  final Widget child;

  @override
  State<_JellySheetWrapper> createState() => _JellySheetWrapperState();
}

class _JellySheetWrapperState extends State<_JellySheetWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _jellyAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _jellyAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _jellyAnim,
      builder: (context, child) {
        final double scale = 0.9 + (_jellyAnim.value * 0.1);
        final double vScale = 1.0 + (1.0 - scale) * 0.8;
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(scale, vScale, 1.0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
