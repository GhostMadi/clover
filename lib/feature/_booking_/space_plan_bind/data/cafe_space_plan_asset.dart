import 'dart:convert';

import 'package:flutter/services.dart';

/// Parsed floor from Resources cafe JSON (createCafeBuilding export).
class CafePlanFloor {
  const CafePlanFloor({
    required this.floorKey,
    required this.label,
    required this.width,
    required this.height,
    required this.backgroundArgb,
    required this.nodes,
  });

  final String floorKey;
  final String label;
  final double width;
  final double height;
  final int backgroundArgb;
  final List<CafePlanNode> nodes;

  List<CafePlanNode> get emojiNodes => nodes.where((n) => n.kind == 'emoji').toList(growable: false);

  /// Места с ценником (role=bookable). Декор-смайлы не входят.
  List<CafePlanNode> get bookableEmojiNodes => emojiNodes.where((n) => n.isBookable).toList(growable: false);

  /// Декор-смайлы (рисуются, без клика/цены).
  List<CafePlanNode> get decorEmojiNodes => emojiNodes.where((n) => !n.isBookable).toList(growable: false);

  /// Каждый bookable emoji на своём месте; общий groupId = связка.
  List<CafeEmojiSpot> get guestEmojiSpots {
    return [
      for (final e in bookableEmojiNodes)
        CafeEmojiSpot(
          nodeId: e.id,
          unitId: _unitIdFor(e),
          nodeIds: _idsInEmojiGroup(e),
          emoji: e.label ?? '📍',
          x: e.x,
          y: e.y,
          size: e.w > e.h ? e.w : e.h,
          groupId: e.groupId,
        ),
    ];
  }

  String _unitIdFor(CafePlanNode e) {
    final ids = _idsInEmojiGroup(e);
    return ids.first;
  }

  List<String> _idsInEmojiGroup(CafePlanNode e) {
    final g = e.groupId;
    if (g == null || g.isEmpty) return [e.id];
    final ids = [
      for (final n in bookableEmojiNodes)
        if (n.groupId == g) n.id,
    ];
    return ids.isEmpty ? [e.id] : ids;
  }
}

/// Точка для тапа гостя. Связка: несколько pin, один unitId / одна цена.
class CafeEmojiSpot {
  const CafeEmojiSpot({
    required this.nodeId,
    required this.unitId,
    required this.nodeIds,
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    this.groupId,
  });

  /// Id этого глифа на схеме.
  final String nodeId;

  /// Id «одного места» (первый в связке) — bind / карточка выбора.
  final String unitId;

  /// Все nodeId связки (или только [nodeId]).
  final List<String> nodeIds;
  final String emoji;
  final double x;
  final double y;
  final double size;
  final String? groupId;

  bool get isCluster => nodeIds.length > 1;
  bool get isUnitPrimary => nodeId == unitId;

  /// Совместимость со старым кодом страницы.
  String get primaryId => unitId;
  int get seatCount => nodeIds.length;
  bool get isTableCluster => isCluster;
}

class CafePlanNode {
  const CafePlanNode({
    required this.id,
    required this.kind,
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.fillArgb,
    required this.strokeArgb,
    required this.strokeWidth,
    required this.radius,
    required this.opacity,
    required this.zIndex,
    required this.groupId,
    required this.points,
    this.role = 'decor',
    this.bookableId,
  });

  final String id;
  final String kind;
  final String? label;
  final double x;
  final double y;
  final double w;
  final double h;
  final int? fillArgb;
  final int strokeArgb;
  final double strokeWidth;
  final double radius;
  final double opacity;
  final int zIndex;
  final String? groupId;
  final List<({double x, double y})>? points;

  /// `bookable` — место с ценником; `decor` — только картинка.
  final String role;
  final String? bookableId;

  bool get isEllipse => kind == 'ellipse';
  bool get isEmoji => kind == 'emoji';
  bool get isText => kind == 'text';
  bool get isLine => kind == 'line' || kind == 'path';
  bool get isPolygon => kind == 'polygon';
  bool get isBookable => role == 'bookable';
}

/// Загрузка схемы барбершопа (mock) для гостевой записи.
abstract final class CafeSpacePlanAsset {
  static const assetPath = 'assets/mocks/barbershop_space_plan.json';

  static List<CafePlanFloor>? _cache;

  static Future<List<CafePlanFloor>> load({bool forceReload = false}) async {
    if (!forceReload && _cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final floorsRaw = map['floors'] as List<dynamic>? ?? const [];
    final floors = <CafePlanFloor>[];
    for (final f in floorsRaw) {
      final fm = f as Map<String, dynamic>;
      final canvas = fm['canvas'] as Map<String, dynamic>? ?? const {};
      final bg = _parseHex(canvas['background'] as String?) ?? 0xFFF6F0E8;
      final nodesRaw = fm['nodes'] as List<dynamic>? ?? const [];
      final nodes = <CafePlanNode>[];
      for (final n in nodesRaw) {
        final nm = n as Map<String, dynamic>;
        final style = nm['style'] as Map<String, dynamic>? ?? const {};
        final frame = nm['frame'] as Map<String, dynamic>?;
        final ptsRaw = nm['points'] as List<dynamic>?;
        List<({double x, double y})>? points;
        if (ptsRaw != null && ptsRaw.isNotEmpty) {
          points = [
            for (final p in ptsRaw) (x: ((p as Map)['x'] as num).toDouble(), y: (p['y'] as num).toDouble()),
          ];
        }
        double x = 0, y = 0, w = 40, h = 40;
        if (frame != null) {
          x = (frame['x'] as num).toDouble();
          y = (frame['y'] as num).toDouble();
          w = (frame['w'] as num).toDouble();
          h = (frame['h'] as num).toDouble();
        } else if (points != null && points.isNotEmpty) {
          final xs = points.map((p) => p.x);
          final ys = points.map((p) => p.y);
          x = xs.reduce((a, b) => a < b ? a : b);
          y = ys.reduce((a, b) => a < b ? a : b);
          w = xs.reduce((a, b) => a > b ? a : b) - x;
          h = ys.reduce((a, b) => a > b ? a : b) - y;
        }
        nodes.add(
          CafePlanNode(
            id: nm['id'] as String? ?? '',
            kind: nm['kind'] as String? ?? 'rect',
            label: nm['label'] as String?,
            x: x,
            y: y,
            w: w,
            h: h,
            fillArgb: _parseHex(style['fill'] as String?),
            strokeArgb: _parseHex(style['stroke'] as String?) ?? 0xFFB54B45,
            strokeWidth: (style['strokeWidth'] as num?)?.toDouble() ?? 2,
            radius: (style['radius'] as num?)?.toDouble() ?? 0,
            opacity: (style['opacity'] as num?)?.toDouble() ?? 1,
            zIndex: (nm['zIndex'] as num?)?.toInt() ?? 0,
            groupId: nm['groupId'] as String?,
            points: points,
            role: nm['role'] as String? ?? 'decor',
            bookableId: nm['bookableId'] as String? ?? nm['bookable_id'] as String?,
          ),
        );
      }
      nodes.sort((a, b) => a.zIndex.compareTo(b.zIndex));
      floors.add(
        CafePlanFloor(
          floorKey: fm['floorKey'] as String? ?? 'floor_1',
          label: fm['label'] as String? ?? '',
          width: (canvas['width'] as num?)?.toDouble() ?? 1280,
          height: (canvas['height'] as num?)?.toDouble() ?? 860,
          backgroundArgb: bg,
          nodes: nodes,
        ),
      );
    }
    _cache = floors;
    return floors;
  }

  static int? _parseHex(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    return int.tryParse(s, radix: 16);
  }
}
