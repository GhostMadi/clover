import 'dart:math' as math;

import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:clover/feature/_booking_/space_plan_bind/data/booking_space_plan_bind_mock.dart';
import 'package:clover/feature/_booking_/space_plan_bind/data/cafe_space_plan_asset.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Гость: зал на весь экран. Холст — цвета плана; хром UI — тема.
class BookingSpacePlanGuestMockPage extends StatefulWidget {
  const BookingSpacePlanGuestMockPage({
    super.key,
    required this.hostId,
    required this.hostDisplayName,
  });

  final String hostId;
  final String hostDisplayName;

  @override
  State<BookingSpacePlanGuestMockPage> createState() => _BookingSpacePlanGuestMockPageState();
}

class _BookingSpacePlanGuestMockPageState extends State<BookingSpacePlanGuestMockPage> {
  final Set<String> _selectedIds = {};
  final _transform = TransformationController();
  List<CafePlanFloor> _floors = const [];
  int _floorIndex = 0;
  var _loading = true;
  String? _loadError;

  String get _pointKey => BookingSpacePlanBindMock.guestShowcaseKey(widget.hostId);

  CafePlanFloor? get _floor =>
      _floors.isEmpty ? null : _floors[_floorIndex.clamp(0, _floors.length - 1)];

  @override
  void initState() {
    super.initState();
    BookingSpacePlanBindMock.ensureGuestShowcase(widget.hostId);
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final floors = await CafeSpacePlanAsset.load(forceReload: true);
      if (!mounted) return;
      final key = BookingSpacePlanBindMock.guestShowcaseKey(widget.hostId);
      // Не затирать бинды с реальным каталогом — их сеет BookingClientPage.
      if (BookingSpacePlanBindMock.binds(key).isEmpty) {
        BookingSpacePlanBindMock.seedGuestBindsFromCafeEmojis(widget.hostId, [
          for (final f in floors)
            for (final n in f.bookableEmojiNodes) (nodeId: n.id, emoji: n.label ?? '💺'),
        ]);
      }
      setState(() {
        _floors = floors;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCanvas());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _fitCanvas() {
    if (!mounted) return;
    final floor = _floor;
    if (floor == null) return;
    final size = MediaQuery.sizeOf(context);
    final topReserve = MediaQuery.paddingOf(context).top + 72;
    final bottomReserve = AppFunctionalScreen.scrollBottomClearance(context) + 88;
    final usableH = (size.height - topReserve - bottomReserve).clamp(160.0, size.height);
    final scaleW = size.width / floor.width;
    final scaleH = usableH / floor.height;
    final scale = math.min(scaleW, scaleH).clamp(0.22, 2.5) * 0.92;
    final dx = (size.width - floor.width * scale) / 2;
    final dy = topReserve + (usableH - floor.height * scale) / 2;
    final m = Matrix4.identity();
    m.setEntry(0, 0, scale);
    m.setEntry(1, 1, scale);
    m.setEntry(0, 3, dx);
    m.setEntry(1, 3, dy);
    _transform.value = m;
  }

  void _selectFloor(int i) {
    setState(() => _floorIndex = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCanvas());
  }

  void _toggleSpot(String nodeId) {
    setState(() {
      final spot = _spotForNode(nodeId);
      final ids = spot?.nodeIds ?? [nodeId];
      final allOn = ids.every(_selectedIds.contains);
      if (allOn) {
        _selectedIds.removeAll(ids);
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  CafeEmojiSpot? _spotForNode(String nodeId) {
    for (final f in _floors) {
      for (final s in f.guestEmojiSpots) {
        if (s.nodeId == nodeId || s.nodeIds.contains(nodeId)) return s;
      }
    }
    return null;
  }

  void _toggleSpotCluster(CafeEmojiSpot spot) {
    HapticFeedback.selectionClick();
    setState(() {
      // Барбершоп: одно кресло за раз.
      final allOn = spot.nodeIds.every(_selectedIds.contains);
      _selectedIds.clear();
      if (!allOn) {
        _selectedIds.addAll(spot.nodeIds);
      }
    });
  }

  List<({CafePlanNode node, BookingEmojiBind bind, CafeEmojiSpot? spot})> _selectedPairs(
    CafePlanFloor floor,
  ) {
    final byId = <String, CafePlanNode>{};
    for (final f in _floors) {
      for (final n in f.nodes) {
        byId.putIfAbsent(n.id, () => n);
      }
    }
    final seenUnits = <String>{};
    final out = <({CafePlanNode node, BookingEmojiBind bind, CafeEmojiSpot? spot})>[];
    for (final id in _selectedIds) {
      final spot = _spotForNode(id);
      if (spot == null) continue;
      if (seenUnits.contains(spot.unitId)) continue;
      seenUnits.add(spot.unitId);
      final bind =
          BookingSpacePlanBindMock.bindFor(_pointKey, spot.unitId) ??
          BookingSpacePlanBindMock.bindFor(_pointKey, spot.nodeId);
      final node = byId[spot.unitId] ?? byId[spot.nodeId];
      if (bind == null || node == null) continue;
      out.add((node: node, bind: bind, spot: spot));
    }
    return out;
  }

  void _popSelection(List<({CafePlanNode node, BookingEmojiBind bind, CafeEmojiSpot? spot})> pairs) {
    Navigator.of(context).pop<List<BookingEmojiBind>>([for (final p in pairs) p.bind]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final bottomPad = AppFunctionalScreen.scrollBottomClearance(context) + 8;
    final floor = _floor;
    final planBg = Color(floor?.backgroundArgb ?? 0xFFF6F0E8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AppFunctionalScreen(
        backgroundColor: planBg,
        collapsed: true,
        collapsedBarWidthPerButton: 72,
        buttons: [
          FunctionalButtonItem(
            icon: AppIcons.back.icon,
            keepWhenCollapsed: true,
            customColor: accent.cta,
            iconColor: accent.ctaForeground,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
        body: _loading
            ? const BookingLoader()
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.base(14, color: colors.subTextColor),
                  ),
                ),
              )
            : ValueListenableBuilder<int>(
                valueListenable: BookingSpacePlanBindMock.revision,
                builder: (context, _, __) {
                  final f = _floor!;
                  final pairs = _selectedPairs(f);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: planBg,
                          child: InteractiveViewer(
                            transformationController: _transform,
                            constrained: false,
                            clipBehavior: Clip.none,
                            panEnabled: true,
                            scaleEnabled: true,
                            minScale: 0.2,
                            maxScale: 4,
                            boundaryMargin: const EdgeInsets.all(800),
                            child: SizedBox(
                              width: f.width,
                              height: f.height,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CustomPaint(
                                    size: Size(f.width, f.height),
                                    painter: _FloorDecorPainter(nodes: f.nodes),
                                  ),
                                  for (final spot in f.guestEmojiSpots)
                                    Positioned(
                                      left: spot.x - 5,
                                      top: spot.y - 5,
                                      child: _GuestEmojiPin(
                                        emoji: spot.emoji,
                                        size: spot.size,
                                        bind: spot.isUnitPrimary
                                            ? (BookingSpacePlanBindMock.bindFor(
                                                  _pointKey,
                                                  spot.unitId,
                                                ) ??
                                                BookingSpacePlanBindMock.bindFor(
                                                  _pointKey,
                                                  spot.nodeId,
                                                ))
                                            : null,
                                        selected: spot.nodeIds.every(_selectedIds.contains),
                                        accentSoft: accent.soft,
                                        accentInk: accent.icon,
                                        onTap: () => _toggleSpotCluster(spot),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Верх: хозяин + этажи
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 0,
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: colors.surface.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.textColor.withValues(alpha: 0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    context.l10n.booking_space_plan_guest_hint(
                                      widget.hostDisplayName,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.base(
                                      13,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textColor,
                                    ),
                                  ),
                                ),
                                if (_floors.length > 1) ...[
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (var i = 0; i < _floors.length; i++)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () => _selectFloor(i),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 180),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: i == _floorIndex
                                                      ? accent.soft
                                                      : colors.surface.withValues(alpha: 0.92),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: i == _floorIndex
                                                        ? accent.icon.withValues(alpha: 0.35)
                                                        : colors.borderSoft,
                                                  ),
                                                ),
                                                child: Text(
                                                  _floors[i].label,
                                                  style: AppTextStyle.base(
                                                    12,
                                                    fontWeight: FontWeight.w700,
                                                    color: i == _floorIndex
                                                        ? accent.onSoft
                                                        : colors.textColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Низ: подсказка или выбор
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: bottomPad,
                        child: pairs.isEmpty
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: colors.surface.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    context.l10n.booking_space_plan_tap_place,
                                    style: AppTextStyle.base(
                                      13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.subTextColor,
                                    ),
                                  ),
                                ),
                              )
                            : _SelectionBar(
                                pairs: pairs,
                                onRemove: (primaryId) {
                                  final spot = _spotForNode(primaryId);
                                  if (spot != null) {
                                    _toggleSpotCluster(spot);
                                  } else {
                                    _toggleSpot(primaryId);
                                  }
                                },
                                onClear: () => setState(() => _selectedIds.clear()),
                                onContinue: () => _popSelection(pairs),
                              ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _FloorDecorPainter extends CustomPainter {
  _FloorDecorPainter({required this.nodes});

  final List<CafePlanNode> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes) {
      if (node.isEmoji && node.isBookable) continue;
      if (node.isEmoji) {
        final glyph = node.label;
        if (glyph == null || glyph.isEmpty) continue;
        final fontSize = math.max(16.0, math.min(node.w, node.h) * 0.72);
        final tp = TextPainter(
          text: TextSpan(text: glyph, style: TextStyle(fontSize: fontSize, height: 1)),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: node.w + 8);
        tp.paint(
          canvas,
          Offset(node.x + node.w / 2 - tp.width / 2, node.y + node.h / 2 - tp.height / 2),
        );
        continue;
      }
      final opacity = node.opacity.clamp(0.0, 1.0);
      final stroke = Color(node.strokeArgb).withValues(alpha: opacity);
      final fill = node.fillArgb != null ? Color(node.fillArgb!).withValues(alpha: opacity) : null;

      if (node.isLine && node.points != null && node.points!.length >= 2) {
        final path = Path()..moveTo(node.points!.first.x, node.points!.first.y);
        for (var i = 1; i < node.points!.length; i++) {
          path.lineTo(node.points![i].x, node.points![i].y);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = stroke
            ..strokeWidth = node.strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
        continue;
      }

      if (node.isPolygon && node.points != null && node.points!.length >= 3) {
        final path = Path()..moveTo(node.points!.first.x, node.points!.first.y);
        for (var i = 1; i < node.points!.length; i++) {
          path.lineTo(node.points![i].x, node.points![i].y);
        }
        path.close();
        if (fill != null) {
          canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = stroke
            ..strokeWidth = node.strokeWidth
            ..style = PaintingStyle.stroke,
        );
        if (node.label != null) {
          _paintLabel(
            canvas,
            node.label!,
            Offset(node.x + node.w / 2, node.y + node.h / 2),
            math.min(14.0, node.h * 0.28),
          );
        }
        continue;
      }

      final rect = Rect.fromLTWH(node.x, node.y, node.w, node.h);
      if (node.isEllipse) {
        if (fill != null) {
          canvas.drawOval(rect, Paint()..color = fill..style = PaintingStyle.fill);
        }
        canvas.drawOval(
          rect,
          Paint()
            ..color = stroke
            ..strokeWidth = node.strokeWidth
            ..style = PaintingStyle.stroke,
        );
      } else {
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(node.radius));
        if (fill != null) {
          canvas.drawRRect(rrect, Paint()..color = fill..style = PaintingStyle.fill);
        }
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = stroke
            ..strokeWidth = node.strokeWidth
            ..style = PaintingStyle.stroke,
        );
      }

      if (node.label != null || node.isText) {
        final fontSize = node.isText
            ? math.max(12.0, math.min(node.h * 0.55, 28.0))
            : math.min(14.0, node.h * 0.28);
        _paintLabel(canvas, node.label ?? '', Offset(node.x + node.w / 2, node.y + node.h / 2), fontSize);
      }
    }
  }

  void _paintLabel(Canvas canvas, String text, Offset center, double fontSize) {
    if (text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D1E)),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 220);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FloorDecorPainter oldDelegate) => !identical(oldDelegate.nodes, nodes);
}

/// Компактная полоса выбора: чипы горизонтально + итог + Далее.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.pairs,
    required this.onRemove,
    required this.onClear,
    required this.onContinue,
  });

  final List<({CafePlanNode node, BookingEmojiBind bind, CafeEmojiSpot? spot})> pairs;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final total = pairs.fold<int>(0, (s, p) => s + p.bind.priceKzt);
    final primary = pairs.first.bind;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.textColor.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primary.emoji, style: const TextStyle(fontSize: 28, height: 1)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primary.serviceTitle,
                      style: AppTextStyle.base(15, fontWeight: FontWeight.w800, color: colors.textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      primary.staffName != null && primary.staffName!.isNotEmpty
                          ? '${context.l10n.booking_space_plan_staff}: ${primary.staffName}'
                          : context.l10n.booking_space_plan_no_staff,
                      style: AppTextStyle.base(13, fontWeight: FontWeight.w600, color: colors.subTextColor),
                    ),
                    Text(
                      context.l10n.booking_space_plan_total(total),
                      style: AppTextStyle.base(13, fontWeight: FontWeight.w800, color: accent.icon),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    context.l10n.booking_space_plan_clear_selection,
                    style: AppTextStyle.base(13, fontWeight: FontWeight.w600, color: colors.subTextColor),
                  ),
                ),
              ),
            ],
          ),
          if (pairs.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pairs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = pairs[i];
                  final emoji = p.spot?.emoji ?? p.node.label ?? '💺';
                  return GestureDetector(
                    onTap: () => onRemove(p.spot?.unitId ?? p.node.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.soft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
                          const SizedBox(width: 6),
                          Text(
                            p.bind.staffName ?? '${p.bind.priceKzt}',
                            style: AppTextStyle.base(
                              12,
                              fontWeight: FontWeight.w800,
                              color: accent.onSoft,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(AppIcons.close.icon, size: 14, color: accent.onSoft.withValues(alpha: 0.65)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            text: pairs.length == 1
                ? context.l10n.booking_space_plan_continue
                : context.l10n.booking_space_plan_continue_n(pairs.length),
            isExpanded: true,
            service: kBookingService,
            onTap: onContinue,
          ),
        ],
      ),
    );
  }
}

class _GuestEmojiPin extends StatelessWidget {
  const _GuestEmojiPin({
    required this.emoji,
    required this.size,
    required this.bind,
    required this.selected,
    required this.accentSoft,
    required this.accentInk,
    required this.onTap,
  });

  final String emoji;
  final double size;
  final BookingEmojiBind? bind;
  final bool selected;
  final Color accentSoft;
  final Color accentInk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = AppServiceAccent.inkOnFill(accentSoft);
    final hit = size + 10;
    final master = bind?.staffName;
    final service = bind?.serviceTitle;

    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (instance) => instance.onTap = onTap,
        ),
      },
      child: SizedBox(
        width: hit,
        height: hit + (selected && bind != null ? 36 : 18),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected ? accentSoft.withValues(alpha: 0.85) : null,
                border: selected ? Border.all(color: accentInk, width: 2.5) : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accentInk.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(emoji, style: TextStyle(fontSize: size * 0.7, height: 1)),
            ),
            if (bind != null)
              Positioned(
                left: -28,
                right: -28,
                top: size - 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentInk.withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: colors.textColor.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${bind!.priceKzt} ₸',
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextStyle.base(10, fontWeight: FontWeight.w800, color: ink),
                      ),
                    ),
                    if (selected && (master != null || service != null)) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: colors.textColor.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (service != null)
                              Text(
                                service,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.base(
                                  10,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textColor,
                                ),
                              ),
                            if (master != null)
                              Text(
                                master,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.base(
                                  10,
                                  fontWeight: FontWeight.w600,
                                  color: accentInk,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
